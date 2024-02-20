# julia --threads=3,1 --project=. -e 'using DancingQueenClient; main("settings.toml")'

using DancingQueenClient

file = "settings.toml"
main(file)

