#!/usr/bin/env python3

import os, argparse, json, math

def gen_conf(template, ofile, vbb, param, param_value, paramfile, file_path, angle=None, trgxpos=None):
    output = ""
    with open(template) as tempfile:
        for line in tempfile:
            if "!!!FILE_PATH!!!" in line:
                output += line.replace("!!!FILE_PATH!!!", str(file_path))
            elif "!!!ANGLE!!!" in line:
                output += line.replace("!!!ANGLE!!!", str(angle))
            elif "!!!TRGXPOS!!!" in line:
                output += line.replace("!!!TRGXPOS!!!", str(trgxpos))
            elif f"!!!{param}!!!" in line:
                if param=="IBIAS":
                    output += line.replace("!!!IBIAS!!!", str(param_value))
                    output += next(tempfile).replace("!!!IBIASN!!!", str(param_value))
                else:
                    output += line.replace(f"!!!{param}!!!", str(param_value))
            elif "!!!VCASB!!!" in line:
                output += line.replace("!!!VCASB!!!", str(paramfile.vcasb))
            elif "!!!IRESET!!!" in line:
                output += line.replace("!!!IRESET!!!", str(paramfile.ireset))
            elif "!!!IBIAS!!!" in line:
                output += line.replace("!!!IBIAS!!!", str(paramfile.ibias))
            elif "!!!IBIASN!!!" in line:
                output += line.replace("!!!IBIASN!!!", str(paramfile.ibiasn))
            elif "!!!IDB!!!" in line:
                output += line.replace("!!!IDB!!!", str(paramfile.idb))
            elif "!!!VCASN!!!" in line:
                output += line.replace("!!!VCASN!!!", str(paramfile.vcasn))
            elif "!!!VBB!!!" in line:
                output += line.replace("!!!VBB!!!", str(vbb))
            else:
                output += line
    with open(ofile, 'w') as of:
        of.write(output)

def param_loop(vbb, paramfile, gen_list, param_list, angle=None, trgxpos=None):
    for param_value in param_list:
        if angle is None:
            if 'I' in paramfile.param:
                    oname=os.path.join(args.outdir,args.prefix+f"VBB{vbb}V_{paramfile.param}{param_value}uA.conf")
            else:
                oname=os.path.join(args.outdir,args.prefix+f"VBB{vbb}V_{paramfile.param}{param_value}mV.conf")
            file_path = f"{paramfile.data_path}{paramfile.ID}/vbb{vbb}/vcasb{paramfile.vcasb}" 
        else:
            if 'I' in paramfile.param:
                oname=os.path.join(args.outdir,args.prefix+f"VBB{vbb}V_{paramfile.param}{param_value}uA_ANGLE{angle}.conf")
            else:
                oname=os.path.join(args.outdir,args.prefix+f"VBB{vbb}V_{paramfile.param}{param_value}mV_ANGLE{angle}.conf")
            file_path = f"{paramfile.data_path}{paramfile.ID}/angle{angle}/vbb{vbb}/vcasb{paramfile.vcasb}" 

        gen_list.append(oname)
        gen_conf(args.template, oname, vbb, paramfile.param, param_value, paramfile, file_path, angle, trgxpos)

if __name__=="__main__":
    parser = argparse.ArgumentParser("Config file generator for the testbeam using the DAQ board")
    parser.add_argument("template", help="Template file.")
    parser.add_argument("paramfile", help="File containing the chip parameter to be looped over and the values to be used.")
    parser.add_argument("--outdir", default="generated_configs/", help="Directory to write output files.")
    parser.add_argument("--prefix", default=None, help="Output filename prefix.")
    parser.add_argument("--clear_dir", action='store_true', help="Remove all files in output dir.")
    args = parser.parse_args()
    
    with open(args.paramfile) as jf:
        paramfile = json.load(jf)
        paramfile = argparse.Namespace(**paramfile)

    # do some checks before launching the scans
    assert paramfile.param in ["VCASB", "VCASN", "IDB", "IRESET", "IBIAS"], f"{paramfile.param} is not a valid chip parameter. Please choose from VCASB, VCASN, IDB, IRESET or IBIAS."
    assert set(float(i) for i in paramfile.VBB_Settings.keys()) == set(i[0] for i in paramfile.VBB_PARAM), "VBB_PARAM and VBB_Settings do not have the same VBB values, please check."
    conf = open(args.template, 'r')
    conflist = conf.readlines()
    conf.close()
    zaber = False
    angles = False
    for line in conflist:
        if "[Producer.ZABER_0]" in line:
            zaber = True
    if paramfile.ANGLES: angles = True
    assert zaber == angles, "Used the angled conf template without angles or used the non-angled conf template with angles." 

    if args.prefix is None:
        args.prefix = os.path.basename(args.template).replace('.conf','').replace('template','')
    if not os.path.exists(args.outdir):
        os.makedirs(args.outdir)
    elif args.clear_dir:
        for f in os.listdir(args.outdir):
            os.remove(os.path.join(args.outdir, f))

    gen_list = []
    for vbb, param_list in paramfile.VBB_PARAM:
        for dac in paramfile.VBB_Settings[str(vbb)].keys():
            setattr(paramfile, dac, paramfile.VBB_Settings[str(vbb)][dac])
        # if not using the rotational stage set paramfile.ANGLES to null and use a non-angled conf template
        if paramfile.ANGLES:
            for angle in paramfile.ANGLES:
                # since the rotational stage does not rotate exactly around the centre
                # need to move in the x-direction by a different amount for each angle
                # the offset is calculated at 60 degrees
                trgxpos=paramfile.trg_x_pos_base+paramfile.trg_x_offset_60deg/(math.sqrt(3)/2)*math.sin(angle/180*math.pi)
                param_loop(vbb, paramfile, gen_list, param_list, angle, trgxpos)
        else:
            param_loop(vbb, paramfile, gen_list, param_list)

    print(f"Generated {len(gen_list)} files.")
    print(','.join(gen_list))
