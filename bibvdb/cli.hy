"
bibvdb - A vector database for your bibliography.

This package provides commands for interacting with a vector database (using
fvdb) stored in-memory using Faiss and a list of dicts and for using Faiss and
pickle for serialization.

Command-line utilities are provided for creating, modifying, and searching the
vector database.
"

(import click)
(import tabulate [tabulate])
(import toolz.dicttoolz [keyfilter])
(import json [dumps])
(import shutil [get-terminal-size])

(import bibvdb.config)
(import bibvdb.db [isbn-doc doi-doc])


(setv default-path (:path bibvdb.config.cfg))

(defn col-widths-to-terminal [widths keys [final False]]
  "Scale a list of relative widths to the terminal width."
  (let [term (get-terminal-size)
        mincolwidth 5
        widths (lfor w widths
                 (max mincolwidth
                      (- (int (/ (* w term.columns)
                                 (sum widths)))
                         1)))]
    (assert (= (len widths) (len keys)))
    ;; setting a minimum column width changes the scaling
    (if final
      widths
      (col-widths-to-terminal widths keys True))))


(defn [(click.group)]
      cli [])

(defn [(click.command) ; info
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")]
  info [path]
  (import fvdb.db [faiss info])
  (let [v (faiss path)]
    (click.echo
      (tabulate (.items (info v))))))

(cli.add-command info)


(defn [(click.command) ; nuke
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")]
  nuke [path]
  (import fvdb.db [faiss nuke write])
  (let [v (faiss path)]
    (nuke v)
    (write v)))

(cli.add-command nuke)

  
(defn [(click.command) ; sources
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")]
  sources [path]
  (import fvdb.db [faiss sources])
  (let [v (faiss path)]
    (for [source (sorted (sources v))]
      (click.echo source))))
  
(cli.add-command sources)

  
(defn [(click.command) ; doi
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")
       (click.argument "dois" :nargs -1)]
  doi [path dois]
  (import fvdb.db [faiss ingest write])
  (click.echo f"Adding: {(.join ", " dois)}")
  (let [v (faiss path)
        docs (lfor i dois (doi-doc i))
        result (ingest v docs)]
    (click.echo f"Added {(:n-records-added result)}.")
    (write v)))
  
(cli.add-command doi)

  
(defn [(click.command) ; isbn
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")
       (click.argument "isbns" :nargs -1)]
  isbn [path isbns]
  (import fvdb.db [faiss ingest write])
  (click.echo f"Adding: {(.join ", " isbns)}")
  (let [v (faiss path)
        docs (lfor i isbns (isbn-doc i))
        result (ingest v docs)]
    (click.echo f"Added {(:n-records-added result)}.")
    (write v)))
  
(cli.add-command isbn)
  

(defn [(click.command) ; similar
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")
       (click.option "-r" "--top" :default 10 :type int :help "Return just top n results.")
       (click.option "-j" "--json" :is-flag True :default False :help "Return results as a json string")
       (click.argument "query")]
  similar [path query * top json]
  (import fvdb.db [faiss similar])
  (let [v (faiss path)
        results (similar v query :top top)
        keys ["source" "title" "authors" "container" "year"]
        widths [15 30 20 20 5]
        colwidths (col-widths-to-terminal widths keys)
        data (lfor d results
               (|
                (dfor k keys k "")
                (keyfilter (fn [k] (in k keys)) d)))]
    (click.echo
      (if json
        (dumps results)
        (tabulate data
                  :headers "keys"
                  :maxcolwidths colwidths
                  :maxheadercolwidths colwidths
                  :floatfmt ".2f")))))
  
(cli.add-command similar)


(defn [(click.command) ; show
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")
       (click.option "-r" "--top" :default 3 :type int :help "Return just top n results.")
       (click.argument "query")]
  show [path query * top]
  (import fvdb.db [faiss similar])
  (let [v (faiss path)
        results (similar v query :top top)]
    (click.echo
      (for [d results]
        (print (:isbn d (:doi d (:source d))))
        (print (:year d ""))
        (print (:summary d))
        (print)))))
  
(cli.add-command show)


(defn [(click.command) ; match
       (click.option "-p" "--path" :default default-path :help "Specify a bibvdb path.")
       (click.option "-r" "--top" :default 10 :type int :help "Return just top n results.")
       (click.option "-f" "--field" :default "title" :help "Field to match against (source, title, authors)")
       (click.option "-j" "--json" :is-flag True :default False :help "Return results as a json string")
       (click.argument "query")]
  match [path query * top field json]
  (import fvdb.db [faiss])
  (import jaro [jaro-winkler-metric])
  (let [v (faiss path)
        keys ["source" "title" "authors" "container" "year"]
        widths [15 25 20 15 5]
        colwidths (col-widths-to-terminal widths keys)
        search-field (hy.models.Keyword field)
        results (lfor r (:records v)
                  {"score" (jaro-winkler-metric query (or (search-field r None) (* "_" 1000)))
                   #** (keyfilter (fn [k] (in k keys)) r)})
        sorted-results (cut (sorted results
                                    :key (fn [r] (:score r))
                                    :reverse True)
                            0 top)]
    (click.echo
      (if json
        (dumps sorted-results)
        (tabulate sorted-results
                  :headers "keys"
                  :maxcolwidths colwidths
                  :maxheadercolwidths colwidths
                  :floatfmt ".2f")))))
  
(cli.add-command match)
