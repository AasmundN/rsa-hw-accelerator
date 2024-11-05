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


# Montgomery exponentiation
def mod_exp(M, e, n):
    e_bits = bitfield(e)

    k = n.bit_length()
    r = 1 << k  # r = 2^k
    r2 = r ** 2 % n

    _M = mon_pro(M, r2, n)
    _x = mon_pro(1, r2, n)

    for e_bit in e_bits:
        _x = mon_pro(_x, _x, n)
        if e_bit == 1:
            _x = mon_pro(_M, _x, n)

    return mon_pro(_x, 1, n)


def main():
    bitsize = 512
    m = 0x019259187

    _, privkey = rsa.newkeys(bitsize)

    e = 0x01BD95573
    n = 0x0253B1447

    encrypted = mod_exp(m, e, n)
    #decrypted = mod_exp(encrypted, d, n)

    print("Message: ", hex(m))
    print("Monpro: ", hex(mon_pro(0x19259187, 0x1D5FE4F2, 0x253B1447)))
    #print("Encrypted: ", hex(encrypted))
    #print("Decrypted: ", decrypted)


if __name__ == "__main__":
    main()
