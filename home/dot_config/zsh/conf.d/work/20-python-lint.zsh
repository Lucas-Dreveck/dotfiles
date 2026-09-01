pythonlint() {
  mkdir -p lint_logs;
  echo "🔍 Running flake8...";
  flake8 . \
    --exclude "**/migrations/0*.py,.venv" \
    --max-line-length 120 \
    --ignore=E203,W503 \
    > lint_logs/flake8.log 2>&1;

  echo "📦 Running isort...";
  isort . \
    --line-width 120 \
    --check-only \
    --diff \
    --profile black \
    --skip-glob "**/migrations/0*.py" \
    --skip .venv \
    > lint_logs/isort.log 2>&1;

  echo "🎨 Running black...";
  black . \
    --check \
    --diff \
    --color \
    --line-length 120 \
    --exclude "^.*\\b(migrations|\\.venv)\\b.*\$" \
    > lint_logs/black.log 2>&1;

  echo "🧠 Running djlint...";
  for dir in $(find . -type d -name templates -not -path "./.venv/*"); do
    djlint "$dir" --profile=django --ignore "H006" >> lint_logs/djlint.log 2>&1;
  done

  echo "🐳 Running hadolint...";
  find . -type f \( -iname "dockerfile" -o -iname "Dockerfile" \) -not -path "./.venv/*" \
    -exec hadolint {} \; > lint_logs/hadolint.log 2>&1;

  echo "✅ Lint finished! Check the files in lint_logs/"
}

alias plint='pythonlint'

alias pfix='
echo "📦 Applying isort...";
isort . --line-width 120 --profile black --skip-glob "**/migrations/0*.py" --skip .venv;

echo "🎨 Applying black...";
black . --line-length 120 --exclude "/(\.venv|migrations)/";

echo "✅ Formatting applied."
'
