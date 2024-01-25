import faiss 
import numpy as np 
import argparse
import os
import ujson

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_dir",
                        default="/home/ec2-user/quic-efs/user/hansizeng/work/t5_pretrainer/t5_pretrainer/experiments-full-t5seq-aq/t5_docid_gen_encoder_1",
                        type=str)
    return parser.parse_args()

if __name__ == "__main__":
    args = get_args()
    model_dir = args.model_dir 
    print("model_dir: ", model_dir)
    mmap_dir = os.path.join(model_dir, "mmap")
    idx_to_docid = {}
    with open(os.path.join(mmap_dir, "text_ids.tsv")) as fin:
        for i, line in enumerate(fin):
            docid = line.strip()
            idx_to_docid[i] = docid 
    print("size of idx_to_docid = {}".format(len(idx_to_docid)))

    doc_embeds = np.memmap(os.path.join(mmap_dir, "doc_embeds.mmap"), dtype=np.float32, mode="r").reshape(-1,768)
    index = faiss.read_index(os.path.join(model_dir, "aq_index/model.index"))
    rq = index.rq
    
    doc_encodings = rq.compute_codes(doc_embeds)

    docid_to_smtid = {}
    for idx, doc_enc in enumerate(doc_encodings):
        docid = idx_to_docid[idx]
        docid_to_smtid[docid] = [-1] + doc_enc.astype(np.int64).tolist()
    
    print("size of docid_to_smtid = {}".format(len(docid_to_smtid)))

    out_dir = os.path.join(model_dir, "aq_smtid")
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)
    
    with open(os.path.join(out_dir, "docid_to_smtid.json"), "w") as fout:
        ujson.dump(docid_to_smtid, fout)

    smtid_to_docids = {}
    for docid, smtids in docid_to_smtid.items():
        smtid = "_".join([str(x) for x in smtids])
        if smtid not in smtid_to_docids:
            smtid_to_docids[smtid] = [docid]
        else:
            smtid_to_docids[smtid] += [docid]
    
    total_smtid = len(smtid_to_docids)
    lengths = np.array([len(x) for x in smtid_to_docids.values()])
    unique_smtid_num = np.sum(lengths == 1)
    print("unique_smtid_num = {}, total_smtid = {}".format(unique_smtid_num, total_smtid))
    print("percentage of smtid is unique = {:.3f}".format(unique_smtid_num / total_smtid))
    print("distribution of lengths: ", np.quantile(lengths, [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]))

    
    