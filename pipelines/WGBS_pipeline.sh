#!/bin/bash
samples=("SRR5836473" "SRR5836474" "SRR5836475", "SRR5836476")
external_dir="/gpfs/vigg_mipt/kropivnitskaya/hw2/raw_data"
internal_dir = "/gpfs/vigg_mipt/kropivnitskaya/hw2/data_processed"
qc_reports_dir="/gpfs/vigg_mipt/kropivnitskaya/hw2/fastqc_reports"

mkdir -p "$external_dir" "$internal_dir" "$qc_reports_dir"

# Функция для обработки одного образца
process_sample() {
    local sample_id="$1"
    
    echo "Обработка образца: $sample_id"
    
    # 1. Загрузка данных (prefetch)
    prefetch --output-directory "$external_dir" "$sample_id"
    
    # 2. Конвертация SRA в FASTQ (parallel-fastq-dump)
    parallel-fastq-dump --outdir "$external_dir" --threads 4 --split-files --gzip --sra-id "$external_dir/$sample_id"
    
    # 3. Контроль качества (FastQC)
    fastqc --threads 4 --outdir "$qc_reports_dir" "$external_dir/${sample_id}_1.fastq.gz" "$external_dir/${sample_id}_2.fastq.gz"
    
    # 4. Обрезка адаптеров (trim_galore)
    trim_galore --paired --fastqc --cores 4 --output_dir "$internal_dir" \
        "$external_dir/${sample_id}_1.fastq.gz" "$external_dir/${sample_id}_2.fastq.gz"
    
    # 5. Выравнивание (Bismark)
    bismark --genome "$genome_index" --parallel 4 --output_dir "$internal_dir" \
        "$internal_dir/${sample_id}_1_val_1.fq.gz" "$internal_dir/${sample_id}_2_val_2.fq.gz"
    
    # 6. Фильтрация выравниваний
    deduplicate_bismark --bam "$internal_dir/${sample_id}_1_val_1_bismark_bt2_pe.bam"
    
    # 7. Экстракция метилирования
    bismark_methylation_extractor --parallel 4 --comprehensive --output "$internal_dir" \
        "$internal_dir/${sample_id}_1_val_1_bismark_bt2_pe.deduplicated.bam"
    
    # 8. Генерация отчетов
    bismark2report --output "$internal_dir/${sample_id}_report.html"
    bismark2summary
}

# Основной цикл по образцам
for sample_id in "${samples[@]}"; do
    process_sample "$sample_id" &
done
