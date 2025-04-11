(import hyjinx [config])
(import fvdb.config [cfg])

(import pathlib [Path])
(import platformdirs [user-state-path user-config-path])


(setv (get cfg "path") (Path (user-state-path "bibvdb") "default.vdb"))

(try
  (setv cfg {#** cfg
             #** (config (Path (user-config-path "bibvdb") "config.toml"))})
  (except [FileNotFoundError]))
