#!/usr/bin/env bash
# Проверка parol.html по трём предикатам из zadanie-4.md.
#
#     ./check-parol.sh
#
# На каждый предикат - одна строка: ДА или НЕТ и причина.
# Последняя строка - ЗЕЛЁНОЕ или КРАСНОЕ. Код завершения 0 только при ЗЕЛЁНОМ.
#
# ЧЕГО ЭТА ПРОВЕРКА НЕ ВИДИТ. Она читает parol.html как текст и ищет теги с
# нужными id. Поэтому она НЕ знает:
#   - работает ли кнопка: JavaScript не запускается, никто ничего не нажимает;
#   - появляется ли пароль, какой он длины и надёжный ли он;
#   - копирует ли кнопка «Копировать» на самом деле и пишется ли «Скопировано»;
#   - видны ли элементы на экране (их могут спрятать через CSS или hidden);
#   - не стоит ли тег внутри HTML-комментария <!-- ... --> - тогда в браузере
#     его нет, а проверка скажет ДА;
#   - не повторяется ли один id дважды;
#   - тег, разорванный на несколько строк (<button\n id="generate">), она не
#     найдёт и скажет НЕТ, хотя кнопка есть.
# Это смотрят глазами в браузере: нажать, увидеть пароль, нажать «Копировать»,
# вставить куда-нибудь.

set -uo pipefail

PAGE=parol.html
FAIL=0

ok()  { echo "ДА  - $1"; }
bad() { echo "НЕТ - $1"; FAIL=$((FAIL+1)); }

# Есть ли в файле тег $1 с id="$2" (кавычки двойные или одинарные).
has_tag() {
  grep -qiE "<$1[[:space:]][^>]*id=[\"']$2[\"']" "$PAGE"
}

# Есть ли в файле любой тег с id="$1".
has_id() {
  grep -qiE "<[a-z][a-z0-9]*[[:space:]][^>]*id=[\"']$1[\"']" "$PAGE"
}

if [ ! -f "$PAGE" ]; then
  bad "1. кнопка id=\"generate\": файла $PAGE нет"
  bad "2. элемент id=\"password\": файла $PAGE нет"
  bad "3. кнопка id=\"copy\" и элемент id=\"copied\": файла $PAGE нет"
else
  # 1. Есть кнопка с id="generate"
  if has_tag button generate; then
    ok "1. кнопка id=\"generate\": найден тег <button id=\"generate\">"
  elif has_id generate; then
    bad "1. кнопка id=\"generate\": id есть, но стоит не на <button>"
  else
    bad "1. кнопка id=\"generate\": в $PAGE нет тега с таким id"
  fi

  # 2. Есть элемент для пароля с id="password"
  if has_id password; then
    ok "2. элемент id=\"password\": найден тег с id=\"password\""
  else
    bad "2. элемент id=\"password\": в $PAGE нет тега с таким id"
  fi

  # 3. Есть кнопка с id="copy" и элемент подтверждения с id="copied"
  if has_tag button copy && has_id copied; then
    ok "3. кнопка id=\"copy\" и элемент id=\"copied\": оба найдены"
  elif ! has_tag button copy && ! has_id copied; then
    bad "3. кнопка id=\"copy\" и элемент id=\"copied\": нет ни кнопки, ни элемента"
  elif ! has_tag button copy; then
    bad "3. кнопка id=\"copy\" и элемент id=\"copied\": нет тега <button id=\"copy\">"
  else
    bad "3. кнопка id=\"copy\" и элемент id=\"copied\": нет тега с id=\"copied\""
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "ЗЕЛЁНОЕ"
else
  echo "КРАСНОЕ"
fi

[ "$FAIL" -eq 0 ]
