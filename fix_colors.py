import os
import glob
import re

files_to_check = glob.glob('lib/presentation/**/*.dart', recursive=True)

for file in files_to_check:
    with open(file, 'r') as f:
        content = f.read()
    
    # Needs import if we use an extension
    if 'context.colors.' not in content and 'AppColors.' in content:
        # Add import
        import_line = "import '../../core/theme/app_colors_extension.dart';\n"
        # for files directly in presentation/screens, the relative path might be different
        # let's just use absolute package import
        import_line = "import 'package:volt/core/theme/app_colors_extension.dart';\n"
        content = import_line + content

    content = content.replace('AppColors.', 'context.colors.')
    
    # We might have invalid consts now. A simple heuristic: 
    # anywhere we have `const SomeWidget(..., context.colors.something)`
    # This is rough. Instead, we can just replace `const ` with ` ` on lines that get `context.colors.`
    lines = content.split('\n')
    for i in range(len(lines)):
        if 'context.colors.' in lines[i]:
            lines[i] = lines[i].replace('const ', '')
            
    with open(file, 'w') as f:
        f.write('\n'.join(lines))
