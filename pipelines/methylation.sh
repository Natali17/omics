#!/bin/bash

# Путь к референсной последовательности
ref_genome="/gpfs/vigg_mipt/kropivnitskaya/hw2/mouse_index/chr12.fa"

# Список идентификаторов образцов
samples=("SRR5836473" "SRR5836474" "SRR5836475" "SRR5836476")

# Количество потоков для параллельной обработки
threads=8

# Директория для выходных файлов
output_dir="dnmtools_output"
mkdir -p "$output_dir"

# Обработка каждого образца по очереди
for sample in "${samples[@]}"
do
    echo "Обработка $sample..."

    # Определяем пути к файлам для данного образца
    input_bam="${sample}_1_val_1_bismark_bt2_pe.deduplicated.bam"
    formatted_bam="${output_dir}/${sample}_format.bam"
    sorted_bam="${output_dir}/${sample}_sorted.bam"
    cpg_meth="${output_dir}/${sample}_CpG.meth"
    sym_cpg_meth="${output_dir}/${sample}_symmetric_CpG.meth"
    filtered_cpg_meth="${output_dir}/${sample}_symmetric_CpG_filtered.meth"

    # Конвертируем BAM-файл, созданный Bismark, в формат, совместимый с dnmtools
    dnmtools format -f bismark -t $threads -B "$input_bam" "$formatted_bam"

    # Сортируем полученный BAM-файл с помощью samtools
    samtools sort -o "$sorted_bam" "$formatted_bam"

    # Извлекаем информацию о метилировании цитозинов только в CpG-контексте
    dnmtools counts -cpg-only -c "$ref_genome" -o "$cpg_meth" "$sorted_bam"

    # Объединяем данные по обеим цепям ДНК (симметричное CpG-метилирование)
    dnmtools sym -o "$sym_cpg_meth" "$cpg_meth"

    # Удаляем участки, помеченные как CpGx (мутации), которые dnmtools не фильтрует автоматически
    awk '$4 != "CpGx"' "$sym_cpg_meth" > "$filtered_cpg_meth"

    echo "Обработка $sample завершена"
    echo "---------------------------"
done

echo "Все образцы обработаны."
exit

