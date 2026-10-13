#!/usr/bin/env python3
"""M6 메타데이터 정합 점검: python3 check_meta.py 01__Requirements_Viewpoint.txt"""
import re, sys

VAL = {'Draft': 0, 'InReview': 1, 'Validated': 2}
CRIT = {'Negligible': 0, 'Minor': 1, 'Major': 2, 'Critical': 3}

def block(lines, i):
    depth, j, seen = 0, i, False
    while j < len(lines):
        depth += lines[j].count('{') - lines[j].count('}')
        seen = seen or '{' in lines[j]
        if seen and depth == 0:
            return j
        j += 1
    return j

def main(path):
    L = open(path, encoding='utf-8', errors='replace').read().replace('\r', '').split('\n')

    # 1) 관심사 목표 유형
    concern = {}
    for i, l in enumerate(L):
        m = re.search(r"concern def (?:<[^>]+> )?(\w+)", l)
        if m:
            txt = "\n".join(L[i:block(L, i) + 1])
            concern[m.group(1)] = 'Hard' if '@HardGoal' in txt else ('Soft' if '@SoftGoal' in txt else '-')

    # 2) SHR 정의
    shr = {}
    for i, l in enumerate(L):
        m = re.search(r"requirement def <'(SHR-[\w-]+)'> (\w+)\s*:>\s*'?([\w-]+)'?", l)
        if not m:
            continue
        txt = "\n".join(L[i:block(L, i) + 1])
        g = lambda p: (re.search(p, txt).group(1) if re.search(p, txt) else None)
        shr[m.group(1)] = dict(
            name=m.group(2), parent=m.group(3),
            goal='Hard' if '@HardGoal' in txt else ('Soft' if '@SoftGoal' in txt else '-'),
            val=g(r"reqValidationStatus = ReqValidationStatus::(\w+)"),
            crit=g(r"criticalityLevel = CriticalityLevel::(\w+)"),
            frames=re.findall(r"frame concern \w+ : (\w+)", txt),
            waiver=('조작화' in txt))
    # 사용(usage) 이름 -> SHR id (stakeholderRequirementSet). 선언이 두 줄에 걸쳐도 잡도록 이름까지만 매칭
    use2id = {}
    for l in L:
        m = re.search(r"requirement <'(SHR-[\w-]+)'> (\w+)", l)
        if m:
            use2id[m.group(2)] = m.group(1)

    def eff(sid, key):                      # 하위 SHR은 상위 값을 상속
        v = shr[sid][key]
        while v is None and shr[sid]['parent'] in shr:
            sid = shr[sid]['parent']; v = shr[sid][key]
        return v

    problems = []
    # C1 하위 SYSR 상태 <= 상위 SHR 상태
    sysr = {}
    for i, l in enumerate(L):
        m = re.search(r"requirement <'(SYSR-[0-9ab]+)'> (\w+)", l)
        if not m:
            continue
        txt = "\n".join(L[i:block(L, i) + 1])
        val = re.search(r"reqValidationStatus = ReqValidationStatus::(\w+)", txt)
        ver = re.search(r"reqVerificationStatus = ReqVerificationStatus::(\w+)", txt)
        crit = re.search(r"criticalityLevel = CriticalityLevel::(\w+)", txt)
        parents = [use2id[p] for p in re.findall(r"stakeholderRequirementSet\.(\w+)", txt) if p in use2id]
        sysr[m.group(1)] = dict(val=val.group(1) if val else None, ver=ver.group(1) if ver else None,
                                crit=crit.group(1) if crit else None, parents=parents,
                                waiver=('상향 근거' in txt))
    for sid, s in sysr.items():
        if not s['parents'] or s['val'] not in VAL:
            continue
        cap = min(VAL[eff(p, 'val')] for p in s['parents'] if eff(p, 'val') in VAL)
        if VAL[s['val']] > cap:
            problems.append(('C1', f"{sid} validation={s['val']} > 상위 {s['parents']} 최저={[k for k,v in VAL.items() if v==cap][0]}"))
    # C2 SHR 목표 유형 vs 관심사 (Soft가 Hard 관심사 아래 금지, Hard가 Soft 관심사 아래는 조작화 근거 필요)
    for sid, s in shr.items():
        for c in s['frames']:
            cg = concern.get(c, '-')
            if s['goal'] == 'Soft' and cg == 'Hard':
                problems.append(('C2', f"{sid} @SoftGoal 인데 관심사 {c} 는 Hard"))
            if s['goal'] == 'Hard' and cg == 'Soft' and not s['waiver']:
                problems.append(('C2', f"{sid} @HardGoal 인데 관심사 {c} 는 Soft (조작화 근거 없음)"))
    # C3 Soft 상위 + Hard 하위: 상위에 조작화 근거 필요
    for sid, s in shr.items():
        kids = [k for k, v in shr.items() if v['parent'] == sid]
        if s['goal'] == 'Soft' and any(shr[k]['goal'] == 'Hard' for k in kids) and not s['waiver']:
            problems.append(('C3', f"{sid} Soft 상위에 Hard 하위 {kids} (조작화 근거 없음)"))
    # C4 SYSR 치명도 <= 상위 치명도 최댓값 (상향 근거가 있으면 예외)
    for sid, s in sysr.items():
        if not s['parents'] or s['crit'] not in CRIT:
            continue
        top = max(CRIT[eff(p, 'crit')] for p in s['parents'] if eff(p, 'crit') in CRIT)
        if CRIT[s['crit']] > top and not s['waiver']:
            problems.append(('C4', f"{sid} criticality={s['crit']} > 상위 최대={[k for k,v in CRIT.items() if v==top][0]} (상향 근거 없음)"))

    for code, msg in problems:
        print(f"[{code}] {msg}")
    print(f"--- 위반 {len(problems)}건 (SYSR {len(sysr)}개, SHR {len(shr)}개 점검)")
    return 1 if problems else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))