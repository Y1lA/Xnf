#!/usr/bin/env python3
"""فحص بنيوي مبسّط لكود Objective-C + بيانات الإصدارات.

ما بيبدّل عن المترجم، بس بيمسك الأغلاط الشائعة: self.<خاصية> غير معلنة،
selector منادى وغير معرّف، أقواس غير متوازنة، و@implementations مفتوحة.
"""

import glob
import json
import re
import sys

UIKIT_PROPS = {
    "view", "navigationItem", "title", "viewController", "presentedViewController",
    "navigationController", "tabBarController", "window", "parentViewController",
    "traitCollection", "preferredContentSize", "edgesForExtendedLayout",
    "modalPresentationStyle", "navigationBar", "sheetPresentationController",
    "popoverPresentationController", "textFields", "tabBarItem", "viewIfLoaded",
    "isViewLoaded", "splitViewController", "extensionContext", "transitioningDelegate",
    "definesPresentationContext", "modalInPresentation", "restorationIdentifier",
    "undoManager", "description", "debugDescription", "childViewControllers",
    "toolbarItems", "inputView", "inputAccessoryView", "nextResponder",
    "contentView", "contentViewController", "refreshControl",
}

UIKIT_METHODS = {
    "init", "dealloc", "viewDidLoad", "viewWillAppear", "viewDidAppear",
    "viewWillDisappear", "viewDidDisappear", "viewDidLayoutSubviews",
    "setNeedsLayout", "layoutSubviews", "layoutIfNeeded", "reloadData",
    "addSubview", "insertSubview", "removeFromSuperview", "becomeFirstResponder",
    "resignFirstResponder", "addObserver", "prepareForReuse", "invalidateIntrinsicContentSize",
    "presentViewController", "dismissViewControllerAnimated", "performSelector",
    "addChildViewController", "removeFromParentViewController", "imageWithActions",
}


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def strip_code(text):
    """يشيل التعليقات والنصوص بحالة صحيحة (مش regex)."""
    out = []
    i, n = 0, len(text)
    in_string = in_line = in_block = escaped = False
    while i < n:
        c = text[i]
        if in_line:
            if c == "\n":
                in_line = False
                out.append(c)
            i += 1
            continue
        if in_block:
            if c == "*" and i + 1 < n and text[i + 1] == "/":
                in_block = False
                i += 2
                continue
            if c == "\n":
                out.append(c)
            i += 1
            continue
        if in_string:
            if escaped:
                escaped = False
            elif c == "\\":
                escaped = True
            elif c == '"':
                in_string = False
                out.append('""')
            i += 1
            continue
        if c == '"':
            in_string = True
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            in_line = True
            i += 2
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            in_block = True
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


problems = []
sources = sorted(glob.glob("*.m"))
headers = sorted(glob.glob("*.h"))
if not sources:
    problems.append("ما لقيت أي ملف .m")

declared_props = set()
declared_methods = set()

for path in headers + sources:
    code = strip_code(read(path))
    if code.count("@interface") + code.count("@implementation") != code.count("@end"):
        problems.append("%s: @interface/@implementation ما تتساوى مع @end" % path)
    for match in re.finditer(r"@property\s*\([^)]*\)[^;]*;", code):
        for ident in re.findall(r"[A-Za-z_]\w*", match.group(0)):
            declared_props.add(ident)
    for match in re.finditer(r"^[-+]\s*\((?:[^()]|\([^()]*\))*\)\s*([^\n{;]+)", code, flags=re.M):
        selector = match.group(1).strip()
        head = re.match(r"[A-Za-z_]\w*", selector)
        if head:
            declared_methods.add(head.group(0))

for path in sources:
    code = strip_code(read(path))

    depth = 0
    for index, line in enumerate(code.split("\n"), 1):
        depth += line.count("[") - line.count("]")
        if depth < 0:
            problems.append("%s:%d زيادة ] أو نقص [" % (path, index))
            depth = 0
    if depth != 0:
        problems.append("%s: عدد [ و] غير متوازن" % path)

    for match in re.finditer(r"self\.([A-Za-z_]\w*)", code):
        name = match.group(1)
        if name not in declared_props and name not in UIKIT_PROPS:
            problems.append("%s: self.%s غير معلَنة كخاصية" % (path, name))

    for match in re.finditer(r"@selector\(([A-Za-z_]\w*)", code):
        name = match.group(1)
        if name not in declared_methods and name not in UIKIT_METHODS:
            problems.append("%s: @selector(%s) ما إلها تعريف" % (path, name))

    for match in re.finditer(r"\[self\s+([A-Za-z_]\w*)", code):
        name = match.group(1)
        if name not in declared_methods and name not in UIKIT_METHODS:
            problems.append("%s: [self %s …] ما إلها تعريف" % (path, name))

data = json.load(open("Resources/editions.json", encoding="utf-8"))
editions = data["editions"]
if len(editions) != 50:
    problems.append("editions.json: عدد الإصدارات %d وليس ٥٠" % len(editions))
if [e["number"] for e in editions] != list(range(1, 51)):
    problems.append("editions.json: أرقام الإصدارات مش ١–٥٠ بالترتيب")
video_ids = [e["videoID"] for e in editions]
if len(set(video_ids)) != len(video_ids):
    problems.append("editions.json: في روابط فيديو مكررة")
for edition in editions:
    stamps = edition["timestamps"]
    if len(stamps) != data["questionsPerEdition"]:
        problems.append("الإصدار %d: عدد التوقيتات %d" % (edition["number"], len(stamps)))
    if stamps != sorted(stamps):
        problems.append("الإصدار %d: التوقيتات مش تصاعدية" % edition["number"])
    if stamps and stamps[-1] >= edition["duration"]:
        problems.append("الإصدار %d: توقيت السؤال الأخير بعد نهاية الفيديو" % edition["number"])
    if edition["duration"] <= 0:
        problems.append("الإصدار %d: مدة غير معروفة" % edition["number"])

print("\n".join(problems))
print("عدد الملفات: %d مصدر + %d هيدر" % (len(sources), len(headers)))
print("عدد الإصدارات: %d × %d سؤال" % (len(editions), data["questionsPerEdition"]))
print("النتيجة:", "في %d ملاحظة" % len(problems) if problems else "ما في ملاحظات بنيوية")
sys.exit(1 if problems else 0)
