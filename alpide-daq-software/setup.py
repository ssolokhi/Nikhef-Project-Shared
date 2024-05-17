"""The ALPIDE DAQ software package
"""

from setuptools import setup
import glob
import os
import shutil

with open("alpidedaqboard/_version.py") as f:
    version = f.readline().strip().split('=')[1].strip("'")

build_dir = "/tmp/alpidedaqboard_install/"
prefix = 'alpide-'
if not os.path.isdir(build_dir):
    os.mkdir(build_dir)
for d in ['scans', 'analyses']:
    for script in glob.glob(d+'/*.py'):
        shutil.copy(script, build_dir+prefix+os.path.basename(script).replace('.py',''))
    
setup(
  name='alpide-daq-software',
  version=version, # https://packaging.python.org/en/latest/single_source_version.html
  description='Software (tools and library) to work the ALPIDE using the DAQ board',
  url='https://gitlab.cern.ch/alice-its3-wp3/alpide-daq-software',

  author='ITS3 WP3',
  author_email='alice-its3-wp3@cern.ch',

  # https://pypi.org/classifiers/
  classifiers=[
    'Development Status :: 3 - Alpha',
    'Intended Audience :: Developers',
    'Topic :: Software Development :: Build Tools',
    'Programming Language :: Python :: 3 :: Only',
  ],

  keywords='ALPIDE, ITS3, ALICE',

  packages=['alpidedaqboard'],

  python_requires='>=3.6, <4',

  install_requires=['pyusb','tqdm','numpy','matplotlib','scipy'],

  package_data={
      'alpidedaqboard':['fw*.json'],
  },

  scripts=[
    'tools/alpide-daq-program',
  ]+glob.glob(build_dir+'alpide-*'),
          
  project_urls={
    'ALICE ITS3 TWiki'              :'https://twiki.cern.ch/ALICE/ITS3'                                 ,
    'ALICE ITS3 WP3 TWiki'          :'https://twiki.cern.ch/ALICE/ITS3WP3'                              ,
    'ALICE ITS3 WP3 DAQ board SW+FW':'https://twiki.cern.ch/twiki/bin/view/ALICE/ITS3WP3DAQboardSWandFW',
    'ALICE ITS3 WP3 GitLab'         :'http://gitlab.cern.ch/alice-its3-wp3/'                            ,
    'Source'                        :'http://gitlab.cern.ch/alice-its3-wp3/alpide-daq-software'         ,
  },
)

