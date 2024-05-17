#define PY_SSIZE_T_CLEAN
#include <Python.h>

static PyObject* decoder_decode_event(PyObject *self,PyObject *args);

static PyMethodDef decoder_methods[]={
  {"decode_event",(PyCFunction)decoder_decode_event,METH_VARARGS,NULL},
  {NULL          ,NULL                             ,0           ,NULL}
};

static struct PyModuleDef decoder_module={
    PyModuleDef_HEAD_INIT,
    "decoder", /* name of module */
    "",          /* module documentation, may be NULL */
    -1,          /* size of per-interpreter state of the module, or -1 if the module keeps state in global variables. */
    decoder_methods
};

PyMODINIT_FUNC PyInit_decoder() {
  return PyModule_Create(&decoder_module);
}

static PyObject* decoder_decode_event(PyObject *self,PyObject *args) {
  uint8_t *data;
  Py_ssize_t n;
  int i; //NB: NOT Py_ssize_t !
  if(!PyArg_ParseTuple(args,"z#i",&data,&n,&i)) return NULL;
  if (!(data[i]==0xAA && data[i+1]==0xAA && data[i+2]==0xAA && data[i+3]==0xAA)) {
      // TODO: raise ValueError...
          return NULL;
  }
  uint64_t tev=0;
  uint32_t iev=0;
  for (int j=0;j<4;++j) iev|=((uint32_t)data[i+4+j])<<(j*8);
  for (int j=0;j<8;++j) tev|=((uint64_t)data[i+8+j])<<(j*8);
  i+=16;
  uint8_t reg;
  PyObject *hit;
  PyObject *hits=PyList_New(0);
  while (i<n) {
    if((data[i]&0xF0)==0xE0) {// chip empty frame
      i+=4;
      goto evtdone;
    } else if((data[i]&0xF0)==0xA0) {// chip header
      i+=2;
      while(i<n) {
        uint8_t data0=data[i];
        if((data0&0xC0)==0x00) {// data long
          uint32_t d=reg<<14|(data0&0x3F)<<8|data[i+1];
          uint16_t x=d>>9&0x3FE|(d^d>>1)&0x1;
          uint16_t y=d>>1&0x1FF;
          hit=Py_BuildValue("ii",x,y);
          PyList_Append(hits,hit);
          Py_DECREF(hit);
          uint8_t data2=data[i+2];
          d+=1;
          while(data2) {
            if(data2&1) {
              x=d>>9&0x3FE|(d^d>>1)&0x1;
              y=d>>1&0x1FF;
              hit=Py_BuildValue("ii",x,y);
              PyList_Append(hits,hit);
              Py_DECREF(hit);
            }
            data2>>=1;
            d+=1;
          }
          i+=3;
        } else if((data0&0xC0)==0x40) {// data short
          uint32_t d=reg<<14|(data0&0x3F)<<8|data[i+1];
          uint16_t x=d>>9&0x3FE|(d^d>>1)&0x1;
          uint16_t y=d>>1&0x1FF;
          //hit=Py_BuildValue("ii",x,y);
          //PyList_Append(hits,hit);
          //Py_DECREF(hit);
          i+=2;
        } else if((data0&0xE0)==0xC0) {// region header
          reg=data0&0x1F;
          i+=1;
        } else if((data0&0xF0)==0xB0) {// chip trailer
          i+=1;
          i=(i+3)/4*4;
          goto evtdone;
        } else if(data0==0xFF) {// IDLE (why?)
          i+=1;
        } else {
          //TODO:raise ValueError('i=%d'%i);
          return NULL;
        }
      }
    } else {
      // TODO: raise ValueError('i=%d'%i)
          return NULL;
    }
  }
  return NULL;
  evtdone:
  if (!(data[i]==0xBB && data[i+1]==0xBB && data[i+2]==0xBB && data[i+3]==0xBB)) {
    // TODO: raise ValueError...
        return NULL;
  }
  i+=4;
  return Py_BuildValue("Niii",hits,iev,tev,i);
}

