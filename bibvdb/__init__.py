"""
bibvdb - A vector database for your bibliography.

`bibvdb` is a simple, minimal wrapper around a FAISS vector database.
You can add DOI and ISBN records.
You can search by semantic distance or jaro-winkler distance.
"""

import hy
import bibvdb.config

# set the package version
__version__ = "0.1.1"
__version_info__ = __version__.split(".")


