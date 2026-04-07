import os

# 定义目录路径
schemas_dir = 'life-power-api/app/schemas'

# 定义重命名映射
rename_map = {
    'alert.py': 'alert_schema.py',
    'charge.py': 'charge_schema.py',
    'energy.py': 'energy_schema.py',
    'user.py': 'user_schema.py',
    'watcher.py': 'watcher_schema.py'
}

# 执行重命名
for old_name, new_name in rename_map.items():
    old_path = os.path.join(schemas_dir, old_name)
    new_path = os.path.join(schemas_dir, new_name)
    if os.path.exists(old_path):
        os.rename(old_path, new_path)
        print(f'Renamed: {old_name} -> {new_name}')
    else:
        print(f'File not found: {old_name}')

print('Rename completed!')
