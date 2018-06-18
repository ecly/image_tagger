["rel", "plugins", "*.exs"]
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Mix.Releases.Config,
    # This sets the default release built by `mix release`
    default_release: :image_tagger,
    # This sets the default environment used by `mix release`
    default_environment: Mix.env()

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"uh}JO_:x%IW@w4|u{jfnb1dWHPEzD@g}5S_n?a*|xRN{L.cSq5Pu%DR|.yZ=3Q_i"
  set output_dir: "rel/image_tagger"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix release`, the first release in the file
# will be used by default

release :image_tagger do
  set version: current_version(:image_tagger)
  set applications: [
    :runtime_tools,
    image_tagger: :permanent
  ]
end
