#!/usr/bin/env python3

import os, argparse

VCASB_VBB_LIST = {
    0.3: list(range(50, 180, 30)),
    0.6: list(range(50, 270, 30)),
    1.2: list(range(100, 350, 30)),
    0.0: list(range(50, 180, 30)),
}

def gen_conf(template, ofile, vbb, vcasb):
    output = ""
    with open(template) as tempfile:
        for line in tempfile:
            if "!!!VCASB!!!" in line:
                output += line.replace("!!!VCASB!!!", str(vcasb))
            elif "!!!VBB!!!" in line:
                output += line.replace("!!!VBB!!!", str(vbb))
            else:
                output += line
    with open(ofile, 'w') as of:
        of.write(output)

if __name__=="__main__":
    parser = argparse.ArgumentParser("Config file generator")
    parser.add_argument("template", help="Template file.")
    parser.add_argument("--output_dir", default="generated_configs/", help="Directory to write output files.")
    parser.add_argument("--prefix", default=None, help="Output filename prefix.")
    parser.add_argument("--clear_dir", action='store_true', help="Remove all files in output dir.")
    args = parser.parse_args()

    if args.prefix is None:
        args.prefix = os.path.basename(args.template).replace('.conf','').replace('template','')
    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)
    elif args.clear_dir:
        for f in os.listdir(args.output_dir):
            os.remove(os.path.join(args.output_dir, f))

    gen_list = []
    for vbb in VCASB_VBB_LIST.keys():
        for vcasb in VCASB_VBB_LIST[vbb]:
            oname=os.path.join(args.output_dir,args.prefix+f"VBB{vbb}_VCASB{vcasb}.conf")
            gen_list.append(oname)
            gen_conf(args.template, oname, vbb, vcasb*0.001)

    print(f"Generated {len(gen_list)} files.")
    print(','.join(gen_list))