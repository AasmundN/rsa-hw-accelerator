import rsa


# get list of bits in n
def bitfield(n):
    return [int(x) for x in bin(n)[2:]]


# calculate Montgomery product using add-shift
# method from RSA Hardware Implementation doc
def mon_pro(A, B, n):
    u = 0

    A_bits = bitfield(A)
    A_bits.reverse()

    # loop over bits in A padded to
    # length k starting from LSB
    for i in range(n.bit_length()):
        if i < len(A_bits):
            u = u + A_bits[i] * B

        if u % 2 == 1:
            u = u + n

        u = u >> 1

    if u >= n:
        u = u - n

    return u


# modular multiplication
# using Blakley's method
def mod_mul(A, B, n):
    A_bits = bitfield(A)

    R = 0

    for A_bit in A_bits:
        R = 2 * R + A_bit * B

        # R <= 4n - 2

        if R >= n:
            R -= n

        if R >= n:
            R -= n

        if R >= n:
            R -= n

    return R


# Montgomery exponentiation
def mod_exp(M, e, n):
    e_bits = bitfield(e)

    k = n.bit_length()
    r = 1 << k  # r = 2^k

    _M = mod_mul(M, r, n)
    _x = mod_mul(1, r, n)

    for e_bit in e_bits:
        _x = mon_pro(_x, _x, n)
        if e_bit == 1:
            _x = mon_pro(_M, _x, n)

    return mon_pro(_x, 1, n)


def main():
    bitsize = 512
    m = 20384723984723912834729387428934

    _, privkey = rsa.newkeys(bitsize)

    e = privkey.e
    d = privkey.d
    n = privkey.n

    encrypted = mod_exp(m, e, n)
    decrypted = mod_exp(encrypted, d, n)

    print("Message: ", m)
    print("Encrypted: ", encrypted)
    print("Decrypted: ", decrypted)


if __name__ == "__main__":
    main()
