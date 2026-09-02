#!/usr/bin/env python3
import json, os, re, argparse, shutil, zipfile, datetime

def sanitize(name):
    import re
    name = (name or '').strip()
    name = re.sub(r'[\\/*?:"<>|]', '_', name)
    name = re.sub(r'\s+', ' ', name)
    return name[:200]

def detect_ext(code, declared_lang):
    mapping = {
        'python':'py','py':'py','powershell':'ps1','ps1':'ps1','ps':'ps1',
        'bash':'sh','sh':'sh','shell':'sh','javascript':'js','js':'js',
        'html':'html','css':'css','json':'json','xml':'xml','sql':'sql','java':'java','cs':'cs'
    }
    if declared_lang:
        ext = mapping.get(declared_lang.lower())
        if ext:
            return ext
    c = (code or '').lstrip()
    if c.startswith('#!') and 'python' in c.splitlines()[0].lower():
        return 'py'
    if 'def ' in c or 'import ' in c:
        return 'py'
    if 'param(' in c or 'Get-ChildItem' in c or 'Write-Host' in c or re.search(r'\bfunction\b', c):
        return 'ps1'
    if c.strip().startswith('<') and 'html' in c.lower():
        return 'html'
    return 'txt'

def parse_nodes(conv):
    mapping = conv.get('mapping') or {}
    nodes = list(mapping.values())
    id_to_node = {n['id']: n for n in nodes if isinstance(n, dict) and 'id' in n}
    roots = [n for n in id_to_node.values() if not n.get('parent')]
    order = []
    visited = set()
    def dfs(node):
        nid = node['id']
        if nid in visited:
            return
        visited.add(nid)
        if node.get('message') and node['message'].get('content'):
            order.append(node)
        for cid in node.get('children', []) or []:
            child = id_to_node.get(cid)
            if child:
                dfs(child)
    for r in roots:
        dfs(r)
    if not order:
        for n in nodes:
            if isinstance(n, dict) and n.get('message'):
                order.append(n)
    return order

def extract_conversation(conv, outbase):
    title = conv.get('title') or 'conversation'
    safe = sanitize(title)
    outdir = os.path.join(outbase, f'extracted_{safe}')
    if os.path.exists(outdir):
        shutil.rmtree(outdir)
    os.makedirs(outdir, exist_ok=True)
    nodes = parse_nodes(conv)
    md_lines = [f'# {title}', f'- extracted_at: {datetime.datetime.utcnow().isoformat()}Z', '']
    summary = {'title': title, 'files': []}
    code_counter = 0
    msg_index = 0
    for node in nodes:
        msg = node.get('message')
        if not msg:
            continue
        author = (msg.get('author') or {}).get('role') or 'unknown'
        create_time = msg.get('create_time') or msg.get('update_time') or ''
        content = msg.get('content') or {}
        if isinstance(content, dict):
            parts = content.get('parts') or []
        elif isinstance(content, list):
            parts = content
        else:
            parts = []
        text = '\n\n'.join([p for p in parts if isinstance(p, str)])
        msg_index += 1
        md_lines.append('---')
        md_lines.append(f'**{msg_index}. {author}**  ' )
        md_lines.append(f'*{create_time}*  ' )
        def repl(m):
            nonlocal code_counter
            lang = (m.group(1) or '').strip().lower()
            code = m.group(2) or ''
            code_counter += 1
            ext = detect_ext(code, lang)
            fname = f'code_{msg_index:03d}_{code_counter:03d}.{ext}'
            fpath = os.path.join(outdir, fname)
            with open(fpath, 'w', encoding='utf-8') as fh:
                fh.write(code)
            summary['files'].append({'file': fname, 'lang': lang or None, 'size': len(code)})
            return f'[Código extraído: {fname}]'
        new_text = re.sub(r'```([\w+-]*)\n(.*?)```', repl, text, flags=re.S)
        md_lines.append(new_text)
    md_path = os.path.join(outdir, f'{safe}.md')
    with open(md_path, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(md_lines))
    with open(os.path.join(outdir, 'summary.json'), 'w', encoding='utf-8') as fh:
        json.dump(summary, fh, ensure_ascii=False, indent=2)
    return outdir

def main():
    parser = argparse.ArgumentParser(description='Extrair conversas de conversations.json')
    parser.add_argument('--input','-i', default='conversations.json')
    parser.add_argument('--outdir','-o', default='extracted')
    parser.add_argument('--title','-t', help='nome completo ou parcial da conversa (case-insensitive)')
    parser.add_argument('--all', action='store_true')
    parser.add_argument('--zip', action='store_true')
    args = parser.parse_args()
    with open(args.input, 'r', encoding='utf-8') as fh:
        data = json.load(fh)
    convs = data if isinstance(data, list) else data.get('conversations') or []
    if args.all:
        toproc = convs
    else:
        if not args.title:
            print('Conversas encontradas:')
            for i,c in enumerate(convs, start=1):
                print(f'{i:03d}: {c.get(\'title\')})')
            sel = input("Digite número ou título parcial para extrair (ou 'all'):\n> ")
            if sel.lower() == 'all':
                toproc = convs
            elif sel.isdigit():
                idx = int(sel)-1
                if 0 <= idx < len(convs):
                    toproc = [convs[idx]]
                else:
                    print('Seleção inválida'); return
            else:
                args.title = sel
        if args.title:
            q = args.title.lower()
            toproc = [c for c in convs if (c.get('title') or '').lower().find(q) != -1]
    os.makedirs(args.outdir, exist_ok=True)
    extracted = []
    for c in toproc:
        out = extract_conversation(c, args.outdir)
        extracted.append(out)
        print('Extraído para', out)
    if args.zip:
        zipname = args.outdir.rstrip('/\\') + '.zip'
        shutil.make_archive(base_name=args.outdir, format='zip', root_dir=args.outdir)
        print('Zip criado:', zipname)

if __name__ == '__main__':
    main()