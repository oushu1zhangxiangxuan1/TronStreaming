import pstats

profile = "profile.out"
p = pstats.Stats("profile.out")
p.strip_dirs().sort_stats("cumulative").print_stats()
