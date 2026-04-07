import os
import shutil

# 定义目录路径
api_dir = 'life-power-api/app/api'

# 定义重命名映射
rename_map = {
    'auth.py': 'auth_router.py',
    'care.py': 'care_router.py',
    'charge.py': 'charge_router.py',
    'energy.py': 'energy_router.py',
    'watchers.py': 'watchers_router.py'
}

# 执行重命名
for old_name, new_name in rename_map.items():
    old_path = os.path.join(api_dir, old_name)
    new_path = os.path.join(api_dir, new_name)
    if os.path.exists(old_path):
        os.rename(old_path, new_path)
        print(f'Renamed: {old_name} -> {new_name}')
    else:
        print(f'File not found: {old_name}')

print('Rename completed!')
