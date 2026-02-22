import re

errors = [
  ("lib/presentation/screens/create_plan_screen.dart", [186, 207, 224, 228, 241]),
  ("lib/presentation/screens/history_screen.dart", [29, 130]),
  ("lib/presentation/screens/plan_management_screen.dart", [30]),
  ("lib/presentation/screens/settings_screen.dart", [85]),
  ("lib/presentation/widgets/volt_text_field.dart", [71]),
]

for file, lines in errors:
    with open(file, 'r') as f:
        content = f.readlines()
    
    for l in lines:
        # Search backwards up to 10 lines from the error line to find 'const ' prefixing a widget open parenthesis
        idx = l - 1
        found = False
        for i in range(idx, max(-1, idx-10), -1):
            if 'const ' in content[i]:
                content[i] = content[i].replace('const ', '')
                found = True
                break
                
    with open(file, 'w') as f:
        f.writelines(content)

