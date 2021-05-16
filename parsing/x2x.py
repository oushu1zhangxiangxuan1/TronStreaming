# bytes object
b = b"example"

# str object
s = "example"

# str to bytes
sb = bytes(s, encoding="utf8")

# bytes to str
bs = str(b, encoding="utf8")

# an alternative method
# str to bytes
sb2 = str.encode(s)

# bytes to str
bs2 = bytes.decode(b)
