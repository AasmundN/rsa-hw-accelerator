import rsa


# get list of bits in n
def bitfield(n):
    return [int(x) for x in bin(n)[2:]]


# calculate Montgomery product using add-shift
# method from RSA Hardware Implementation doc
def monpro(A, B, n):
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


# Montgomery exponentiation
def modexp(M, e, n):
    e_bits = bitfield(e)

    k = n.bit_length()
    r = 1 << k  # r = 2^k
    r2 = r ** 2 % n

    _M = monpro(M, r2, n)
    _x = monpro(1, r2, n)

    for e_bit in e_bits:
        _x = monpro(_x, _x, n)
        if e_bit == 1:
            _x = monpro(_M, _x, n)

    return monpro(_x, 1, n)


def main():
    bitsize = 512
    m = 20384723984723912834729387428934

    _, privkey = rsa.newkeys(bitsize)

    e = privkey.e
    d = privkey.d
    n = privkey.n

    encrypted = modexp(m, e, n)
    decrypted = modexp(encrypted, d, n)

    print("Message: ", m)
    print("Encrypted: ", encrypted)
    print("Decrypted: ", decrypted)


if __name__ == "__main__":
    main()
