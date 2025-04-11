"
Manage interaction with fvdb.

fvdb expects records in form:
    `{summary embedding hash-id #** metadata}`)

The summary data gets used in the distance (similarity) calculation,
so only relevant words should go in there.
"

(import json)
(import requests)
(import datetime [datetime])

(import hyjinx [hash-id now])

(import bibsearch.doi [get-doi])
(import bibsearch.isbn [get-isbn])

(import fvdb.embeddings [token-count embed])


(defn doi-doc [doi]
  "Create a list of a single doc from a DOI.
  Return it with the summary, its embedding, and metadata."
  (try
    (let [details (get-doi doi)
          title (:title details "")
          subtitle (:subtitle details "")
          container (get details "container-title")
          authors (:authors details "")
          abstract (:abstract details "")
          reference (:reference details "")
          year (get details "deposited" "date-parts" 0 0)
          summary f"{title}\n{subtitle}\n{container}\n{authors}\n{abstract}"
          doi (:doi details doi)]
       {"added" (now)
        "summary" summary
        "embedding" (embed summary) ; will be truncated if too long
        "hash" (hash-id summary)
        "length" (token-count summary)
        "doi" doi
        "source" doi
        "url" (:url details f"https://doi.org/{doi}")
        "reference" reference
        "title" title
        "container" container
        "authors" authors
        "year" year
        "abstract" abstract})
    (except [e [Exception]]
      {"error" (repr e)})))

(defn isbn-doc [isbn]
  "Create a list of a single doc from an ISBN.
  Return it with the summary, its embedding, and metadata."
  (try
    (let [details (get-isbn isbn)
          title (:title details "")
          subtitle (:subtitle details "")
          authors (.join "; " (:authors details ""))
          publisher (:publisher details "")
          description (:description details "")
          year (:year details)
          summary f"{title}\n{subtitle}\n{publisher}\n{authors}\n{description}"]
       {"added" (now)
        "summary" summary
        "embedding" (embed summary) ; will be truncated if too long
        "hash" (hash-id summary)
        "length" (token-count summary)
        "isbn" (:isbn details isbn)
        "isbn_10" (:isbn-10 details)
        "isbn_13" (:isbn-13 details)
        "source" isbn
        "publisher" publisher
        "url" (:canonicalVolumeLink details)
        "title" title
        "authors" authors
        "description" description
        "year" year})
    (except [e [Exception]]
      {"error" (repr e)})))
