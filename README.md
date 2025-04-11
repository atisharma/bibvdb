# bibvdb

This is essentially a vector database recommendation engine for your bibliography.
Each record contains the DOI or ISBN and the obvious metadata.


## Manage and query a vector database of bibliographic references

It is possible to search by topic or phrase against the database.
Searches are made against the title, authors, and (if available) abstract or description.

```
$ bibvdb show "My really interesting topic"
$ bibvdb similar "My really interesting topic"
```

You can add records by ISBN or DOI, which will be looked up online.

```
$ bibvdb doi "my/doi"
$ bibvdb isbn "my-isbn"
```

## Configuration

Configuration is essentially the same as `fvdb`, but the config file is located in `$XDG_CONFIG_DIR/bibvdb`. The defaults are probably fine, though.

## Todo

Add the ability to crawl via the references retrieved within a DOI record (one layer deep).

