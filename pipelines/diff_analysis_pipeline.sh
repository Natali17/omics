#!/bin/bash

# 1. Определяем имя образца
basename="8_cell"

# 2. Объединяем файлы метилирования репликатов
dnmtools merge -o "${basename}_WGBS.meth" ./bismark/dnmtools_output/SRR5836473_symmetric_CpG_filtered.meth ./bismark/dnmtools_output/SRR5836474_symmetric_CpG_filtered.meth
dnmtools merge -o "ICM_WGBS.meth" ./bismark/dnmtools_output/SRR5836475_symmetric_CpG_filtered.meth ./bismark/dnmtools_output/SRR5836476_symmetric_CpG_filtered.meth

# 3. Сравниваем метилирование
dnmtools diff -o "${basename}_vs_ICM.diff" "${basename}_WGBS.meth" ICM_WGBS.meth

# 4. Генерируем HMR для обеих групп
dnmtools hmr -p params.txt -o ${basename}_merge_WGBS.hmr ${basename}_WGBS.meth
dnmtools hmr -p params.txt -o ICM_merge_WGBS.hmr ICM_WGBS.meth

# 5. Определяем DMR
dnmtools dmr "${basename}_vs_ICM.diff" ${basename}_merge_WGBS.hmr ICM_merge_WGBS.hmr dmr-${basename}-lt-ICM.bed dmr-ICM_lt-${basename}.bed

# 6. Проверяем, создался ли DMR файл
if [ ! -f dmr-${basename}-lt-ICM.bed ]; then
    echo "Ошибка: DMR файл dmr-${basename}-lt-ICM.bed не найден. Прерывание."
    exit 1
fi

# 7. Пересечение DMR (опционально)
bedtools intersect -a dmr-${basename}-lt-ICM.bed -b dmr-ICM_lt-${basename}.bed > common.bed

# 8. Фильтрация DMR по количеству CpG и уровню различия
awk -F '[:\t]' '$5 >= 5 && $6/$5 >= 0.8' dmr-${basename}-lt-ICM.bed > dmr-${basename}-lt-ICM-filtered.bed
awk -F '[:\t]' '$5 >= 5 && $6/$5 >= 0.8' dmr-ICM_lt-${basename}.bed > dmr-ICM_lt-${basename}-filtered.bed

# 9. Скачиваем и подготавливаем аннотацию генов, если её нет
if [ ! -f "gencode.vM10.annotation.sorted.bed" ]; then
    wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_mouse/release_M10/gencode.vM10.annotation.gtf.gz
    gunzip gencode.vM10.annotation.gtf.gz
    awk '$3 == "gene" {match($0, /gene_id "([^"]+)"/, arr); if (arr[1] != "") print $1"\t"$4-1"\t"$5"\t"arr[1]; }' gencode.vM10.annotation.gtf > gencode.vM10.annotation.bed
    sort -k1,1 -k2,2n gencode.vM10.annotation.bed > gencode.vM10.annotation.sorted.bed
    echo "Файл успешно создан: gencode.vM10.annotation.sorted.bed"
else
    echo "Файл уже существует: gencode.vM10.annotation.sorted.bed"
fi

# 10. Поиск ближайших генов ТОЛЬКО для фильтрованных DMR
closestBed -a dmr-ICM_lt-8_cell.bed -b gencode.vM10.annotation.sorted.bed > dmr-ICM_lt-8_cell_closest_genes.txt
closestBed -a dmr-8_cell-lt-ICM.bed -b gencode.vM10.annotation.sorted.bed > dmr-8_cell-lt-ICM_closest_genes.txt

# 11. Отбираем нужные колонки



awk '{print $2, $3, $5, $8, $9, $10}' dmr-ICM_lt-8_cell_closest_genes.txt  > dmr-ICM_lt-8_cell_gene_ids.txt
awk '{print $2, $3, $5, $8, $9, $10}' dmr-8_cell-lt-ICM_closest_genes.txt  > dmr-8_cell-lt-ICM_gene_ids.txt

exit


