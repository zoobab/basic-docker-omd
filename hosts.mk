# Written by WATO
# encoding: utf-8

all_hosts += [
  "localhost|cmk-agent|prod|lan|tcp|wato|/" + FOLDER_PATH + "/",
]


# Host attributes (needed for WATO)
host_attributes.update(
{'localhost': {}})
