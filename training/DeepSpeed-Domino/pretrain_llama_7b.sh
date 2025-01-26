# Copyright (c) 2022, NVIDIA CORPORATION.  All rights reserved.
# This file is adapted from pretrain_llama.sh in Megatron-LM

#!/bin/bash

export CUDA_DEVICE_MAX_CONNECTIONS=1
 
GPUS_PER_NODE=2
# Change for multinode config
MASTER_ADDR=localhost
MASTER_PORT=6000
NNODES=1
NODE_RANK=0
WORLD_SIZE=$(($GPUS_PER_NODE*$NNODES))
 
CHECKPOINT_PATH=checkpoint
rm -rf $CHECKPOINT_PATH/*
VOCAB_FILE="dataset/gpt2-vocab.json"
MERGE_FILE="dataset/gpt2-merges.txt"
DATA_PATH="dataset/my-gpt2_text_document"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export PYTHONPATH=$SCRIPT_DIR:$PYTHONPATH
 
DISTRIBUTED_ARGS="
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $NNODES \
    --node_rank $NODE_RANK \
    --master_addr $MASTER_ADDR \
    --master_port $MASTER_PORT
"
 
LLAMA_ARGS="
    --num-layers 32 \
    --hidden-size 4096 \
    --num-attention-heads 32 \
    --seq-length 1024 \
    --max-position-embeddings 1024 \
    --position-embedding-type rope \
    --swiglu \
    --ffn-hidden-size 11008\
    --normalization RMSNorm \
    --layernorm-epsilon 1e-6 \
    --micro-batch-size 16 \
    --global-batch-size 16 \
    --lr 0.00015 \
    --train-iters 80 \
    --lr-decay-iters 320000 \
    --lr-decay-style cosine \
    --min-lr 1.0e-5 \
    --weight-decay 1e-2 \
    --lr-warmup-fraction .01 \
    --clip-grad 1.0 \
    --fp16 \
    --tensor-model-parallel-size $WORLD_SIZE \
    --seed 3407 
"

DATA_ARGS="
    --data-path $DATA_PATH \
    --vocab-file $VOCAB_FILE \
    --merge-file $MERGE_FILE \
    --split 949,50,1
"
 
OUTPUT_ARGS="
    --log-interval 1 \
    --save-interval 10000 \
    --eval-interval 1000 \
    --eval-iters 1
"
 
cmd="deepspeed --num_gpus $WORLD_SIZE \
    pretrain_llama.py \
    $LLAMA_ARGS \
    $DATA_ARGS \
    $OUTPUT_ARGS 
    "
echo $cmd
eval $cmd 
