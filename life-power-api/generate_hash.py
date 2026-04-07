from passlib.hash import sha256_crypt

password = "password123"
hash_value = sha256_crypt.hash(password)
print(f"Hash for '{password}': {hash_value}")
