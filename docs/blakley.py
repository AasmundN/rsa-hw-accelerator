import rsa


# get list of bits in n
def bitfield(n):
    return [int(x) for x in bin(n)[2:]]


def mod_mul(A, B, n):
    A_bits = bitfield(A)

    R = 0

    for i in range(A.bit_length()):
        R = 2 * R + A_bits[i] * B

        if R >= n:
            R -= n

        if R >= n:
            R -= n

    return R


def mod_exp(M, e, n):
    e_bits = bitfield(e)

    C = 1

    for e_bit in e_bits:
        C = mod_mul(C, C, n)

        if e_bit == 1:
            C = mod_mul(C, M, n)

    return C


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
