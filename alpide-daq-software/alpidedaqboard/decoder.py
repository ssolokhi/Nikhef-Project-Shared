#@profile
def decode_event(data,i=0):
    if i==0 and data[:16]==b'\xaa\xaa\xaa\xaa\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00':
        print(f" Decoder: stray sequence {data[:16]} found. Skipping 16 bytes.")
        i+=16
    assert list(data[i:i+4])==[0xAA]*4
    iev=sum(b<<(j*8) for j,b in enumerate(data[i+4:i+ 8]))
    tev=sum(b<<(j*8) for j,b in enumerate(data[i+8:i+16]))
    i+=4*4
    hits=[]
    if   data[i]&0xF0==0xE0: # chip empty frame
         assert data[i+2]==0xFF
         assert data[i+3]==0xFF
         i+=4
    elif data[i]&0xF0==0xA0: # chip header
        i+=2
        n=len(data)
        reg=None
        while i<n:
            data0=data[i]
            if   data0&0xC0==0x00: # data long
                d=reg<<14|(data0&0x3F)<<8|data[i+1]
                hits.append((d>>9&0x3FE|(d^d>>1)&0x1,d>>1&0x1FF))
                data2=data[i+2]
                d+=1
                while data2:
                    if data2&1:
                        hits.append((d>>9&0x3FE|(d^d>>1)&0x1,d>>1&0x1FF))
                    data2>>=1
                    d+=1
                i+=3
            elif data0&0xC0==0x40: # data short
                d=reg<<14|(data0&0x3F)<<8|data[i+1]
                hits.append((d>>9&0x3FE|(d^d>>1)&0x1,d>>1&0x1FF))
                i+=2
            elif data0&0xE0==0xC0: # region header
                reg=data0&0x1F
                i+=1
            elif data0&0xF0==0xB0: # chip trailer
                i+=1
                i=(i+3)//4*4
                break
            elif data0==0xFF:
                i+=1
            else:
                print("DEBUG: data[i-10:i+10]:", data[i-10:i+10])
                raise ValueError(f'i={i}: {data[i]:02x}')
    else:
        print("DEBUG: data[i-10:i+10]:", data[i-10:i+10])
        raise ValueError(f'i={i}: {data[i]:02x}')
    assert list(data[i:i+4])==[0xBB]*4
    i+=4
    return hits,iev,tev,i
def main(d):
    nev=0
    i=0
    pbar=tqdm(total=len(d))
    while i<len(d):
        hits,iev,tev,j=decode_event(d,i)
        pbar.update(j-i)
        i=j
        print(i,iev,tev,len(hits))
        nev+=1
    print('Decoded %d event(s)'%nev)

if __name__=='__main__':
    import sys
    from tqdm import tqdm
    with open(sys.argv[1],'rb') as f:
        d=bytearray(f.read())
        main(d)
