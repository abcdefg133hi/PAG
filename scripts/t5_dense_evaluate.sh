#!/bin/bash
task=all_aq_pipline
data_root_dir=/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco
collection_path=$data_root_dir/full_collection/
q_collection_paths='["/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/TREC_DL_2019/queries_2019/","/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/TREC_DL_2020/queries_2020/","/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/dev_queries/"]'
eval_qrel_path='["/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/dev_qrel.json","/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/TREC_DL_2019/qrel.json","/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/TREC_DL_2019/qrel_binary.json","/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/TREC_DL_2020/qrel.json","/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/TREC_DL_2020/qrel_binary.json"]'
experiment_dir=experiments-full-lexical-ripor

echo $task
if [ $task = "all_pipeline" ]; then
    model_dir="/home/ec2-user/quic-efs/user/hansizeng/work/term_generative_retriever/$experiment_dir/t5-full-dense-1-5e-4-12l"
    pretrained_path=$model_dir/checkpoint
    index_dir=$model_dir/index
    out_dir=$model_dir/out

    python -m torch.distributed.launch --nproc_per_node=8 -m t5_pretrainer.evaluate \
        --pretrained_path=$pretrained_path \
        --index_dir=$index_dir \
        --out_dir=$out_dir \
        --task=index \
        --encoder_type=t5seq_pretrain_encoder \
        --collection_path=$collection_path
    python -m t5_pretrainer.evaluate \
        --task=index_2 \
        --index_dir=$index_dir 

    python -m t5_pretrainer.evaluate \
        --task=dense_retrieve \
        --pretrained_path=$pretrained_path \
        --index_dir=$index_dir \
        --out_dir=$out_dir \
        --encoder_type=t5seq_pretrain_encoder \
        --q_collection_paths=$q_collection_paths \
        --eval_qrel_path=$eval_qrel_path
elif [ $task = "retrieve_train_queries" ]; then 
    echo "run retrieve_train_queries task"

    # the model_dir should be changed every time
    model_dir="/home/ec2-user/quic-efs/user/hansizeng/work/term_generative_retriever/$experiment_dir/t5-dense-1"
    pretrained_path=$model_dir/checkpoint
    index_dir=$model_dir/index
    out_dir=$model_dir/out

    python -m t5_pretrainer.evaluate \
        --task=dense_retrieve \
        --pretrained_path=$pretrained_path \
        --index_dir=$index_dir \
        --out_dir=$out_dir  \
        --q_collection_paths='["/home/ec2-user/quic-efs/user/hansizeng/work/data/msmarco/train_queries/labeled_queries/"]' \
        --topk=100 \
        --encoder_type=t5seq_pretrain_encoder
elif [ $task = all_aq_pipline ]; then 
    echo "task: $task"

    model_dir="/home/ec2-user/quic-efs/user/hansizeng/work/term_generative_retriever/$experiment_dir/t5-full-dense-1-5e-4-12l"
    pretrained_path=$model_dir/checkpoint
    index_dir=$model_dir/aq_index
    mmap_dir=$model_dir/mmap
    out_dir=$model_dir/aq_out

    M=8
    nbits=11
    K=$((2 ** $nbits))
    echo M: $M nbits: $nbits K: $K
    echo $model_dir

    #python -m torch.distributed.launch --nproc_per_node=8 -m t5_pretrainer.evaluate \
    #    --pretrained_path=$pretrained_path \
    #    --index_dir=$mmap_dir \
    #    --task=mmap \
    #    --collection_path=$collection_path

    #python -m t5_pretrainer.evaluate \
    #    --task=mmap_2 \
    #    --index_dir=$mmap_dir \
    #    --mmap_dir=$mmap_dir

    #python -m t5_pretrainer.evaluate \
    #    --task=aq_index \
    #    --codebook_num=$M \
    #    --codebook_bits=$nbits \
    #    --index_dir=$index_dir \
    #    --mmap_dir=$mmap_dir

    #python -m t5_pretrainer.evaluate \
    #    --task=aq_retrieve \
    #    --pretrained_path=$pretrained_path \
    #    --index_dir=$index_dir \
    #    --out_dir=$out_dir \
    #    --q_collection_paths=$q_collection_paths \
    #    --eval_qrel_path=$eval_qrel_path  \
    #    --mmap_dir=$mmap_dir

    #python t5_pretrainer/preprocess/create_customized_smtid_file.py \
    #    --model_dir=$model_dir \
    #    --M=$M \
    #    --bits=$nbits

    python -m t5_pretrainer.preprocess.change_customized_embed_layer \
        --model_dir=$model_dir \
        --K=$K
else 
echo "Error: Unknown task."
exit 1
fi