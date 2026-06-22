import re

translations = {
    'te': {
        'home': 'హోమ్',
        'properties': 'ఆస్తులు',
        'tenants': 'అద్దెదారులు',
        'finance': 'ఆర్థిక',
        'alerts': 'హెచ్చరికలు',
        'settings': 'సెట్టింగ్‌లు',
        'appLanguage': 'యాప్ భాష',
        'selectLanguage': 'భాషను ఎంచుకోండి',
        'appPreferences': 'యాప్ ప్రాధాన్యతలు',
        'appearance': 'స్వరూపం',
        'darkMode': 'డార్క్ మోడ్'
    },
    'ta': {
        'home': 'முகப்பு',
        'properties': 'சொத்துக்கள்',
        'tenants': 'குத்தகைதாரர்கள்',
        'finance': 'நிதி',
        'alerts': 'எச்சரிக்கைகள்',
        'settings': 'அமைப்புகள்',
        'appLanguage': 'பயன்பாட்டு மொழி',
        'selectLanguage': 'மொழியைத் தேர்ந்தெடுக்கவும்',
        'appPreferences': 'பயன்பாட்டு விருப்பத்தேர்வுகள்',
        'appearance': 'தோற்றம்',
        'darkMode': 'இருண்ட முறை'
    },
    'es': {
        'home': 'Inicio',
        'properties': 'Propiedades',
        'tenants': 'Inquilinos',
        'finance': 'Finanzas',
        'alerts': 'Alertas',
        'settings': 'Ajustes',
        'appLanguage': 'Idioma de la App',
        'selectLanguage': 'Seleccionar Idioma',
        'appPreferences': 'Preferencias de la App',
        'appearance': 'Apariencia',
        'darkMode': 'Modo Oscuro'
    },
    'zh': {
        'home': '首页',
        'properties': '房产',
        'tenants': '租客',
        'finance': '财务',
        'alerts': '通知',
        'settings': '设置',
        'appLanguage': '应用语言',
        'selectLanguage': '选择语言',
        'appPreferences': '应用首选项',
        'appearance': '外观',
        'darkMode': '深色模式'
    }
}

for lang, trans in translations.items():
    file_path = f'lib/l10n/app_{lang}.arb'
    with open(file_path, 'r', encoding='utf-8') as f:
        data = f.read()
    
    for key, value in trans.items():
        data = re.sub(rf'"{key}":\s*".*?"', f'"{key}": "{value}"', data)
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(data)
