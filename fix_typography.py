import glob

files_to_check = glob.glob('lib/presentation/**/*.dart', recursive=True)

for file in files_to_check:
    with open(file, 'r') as f:
        content = f.read()
    
    if 'AppTypography.textTheme' in content:
        content = content.replace('AppTypography.textTheme', 'Theme.of(context).textTheme')
        with open(file, 'w') as f:
            f.write(content)
