from distutils.core import setup, Extension

def main():
    setup(name="decoder",
          version="1.0.0",
          description="foo",
          author="<Magnus Mager",
          author_email="Magnus.Mager@cern.ch",
          ext_modules=[Extension("decoder", ["decoder.c"])])

if __name__ == "__main__":
    main()

