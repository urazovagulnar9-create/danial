#!/usr/bin/env bash
# Проверка parol.html по трём предикатам из zadanie-4.md (1-3)
# и трём предикатам из zadanie-5.md (4-6).
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
#   - двигается ли ползунок, меняется ли число в id="length-value" и
#     становится ли пароль той длины, что выбрана на ползунке;
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

# Весь первый тег $1 с id="$2" целиком, чтобы смотреть его атрибуты.
get_tag() {
  grep -oiE "<$1[[:space:]][^>]*id=[\"']$2[\"'][^>]*>" "$PAGE" | head -n 1
}

# Есть ли в теге $1 атрибут $2="$3".
tag_has_attr() {
  echo "$1" | grep -qiE "[[:space:]]$2=[\"']$3[\"']"
}

if [ ! -f "$PAGE" ]; then
  bad "1. кнопка id=\"generate\": файла $PAGE нет"
  bad "2. элемент id=\"password\": файла $PAGE нет"
  bad "3. кнопка id=\"copy\" и элемент id=\"copied\": файла $PAGE нет"
  bad "4. ползунок id=\"length\": файла $PAGE нет"
  bad "5. элемент id=\"length-value\": файла $PAGE нет"
  bad "6. у ползунка min=\"8\" и max=\"32\": файла $PAGE нет"
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

  # 4. Есть ползунок с id="length" (тег <input type="range">)
  SLIDER=$(get_tag input length)
  if [ -n "$SLIDER" ] && tag_has_attr "$SLIDER" type range; then
    ok "4. ползунок id=\"length\": найден тег <input type=\"range\" id=\"length\">"
  elif [ -n "$SLIDER" ]; then
    bad "4. ползунок id=\"length\": <input id=\"length\"> есть, но без type=\"range\""
  elif has_id length; then
    bad "4. ползунок id=\"length\": id есть, но стоит не на <input>"
  else
    bad "4. ползунок id=\"length\": в $PAGE нет тега с таким id"
  fi

  # 5. Есть элемент с id="length-value" для выбранной длины
  if has_id length-value; then
    ok "5. элемент id=\"length-value\": найден тег с id=\"length-value\""
  else
    bad "5. элемент id=\"length-value\": в $PAGE нет тега с таким id"
  fi

  # 6. У ползунка id="length" есть min="8" и max="32"
  if [ -z "$SLIDER" ]; then
    bad "6. у ползунка min=\"8\" и max=\"32\": нет тега <input id=\"length\">"
  elif tag_has_attr "$SLIDER" min 8 && tag_has_attr "$SLIDER" max 32; then
    ok "6. у ползунка min=\"8\" и max=\"32\": оба атрибута найдены"
  elif ! tag_has_attr "$SLIDER" min 8 && ! tag_has_attr "$SLIDER" max 32; then
    bad "6. у ползунка min=\"8\" и max=\"32\": нет ни min=\"8\", ни max=\"32\""
  elif ! tag_has_attr "$SLIDER" min 8; then
    bad "6. у ползунка min=\"8\" и max=\"32\": нет min=\"8\""
  else
    bad "6. у ползунка min=\"8\" и max=\"32\": нет max=\"32\""
  fi
fi

if [ "$FAIL" -eq 0 ]; then
  echo "ЗЕЛЁНОЕ"
else
  echo "КРАСНОЕ"
fi

[ "$FAIL" -eq 0 ]
