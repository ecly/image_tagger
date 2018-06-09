use Mix.Config

# In this file, we keep production configuration that
# you'll likely want to automate and keep away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or yourself later on).
config :image_tagger, ImageTaggerWeb.Endpoint,
  secret_key_base: ""

config :ex_aws,
  s3: [region: "eu-west-2", scheme: "https://"],
  access_key_id: [{:system, ""}, :instance_role],
  secret_access_key: [{:system, ""}, :instance_role]

config :image_tagger, image_bucket: "****-****-*****-*****"
config :image_tagger, bad_bucket: "****-****-*****-*****"
config :image_tagger, good_bucket: "****-****-*****-*****"
