#!/usr/bin/env python3
"""
Compare ENLIGHT Program CSV vs Validation - Rule by Rule Detail
Find EXACTLY which CA/BP is missing in each rule.

Usage:
    python compare_rules_detail.py program_csv.csv
    python compare_rules_detail.py program_csv.csv --rule 1
    python compare_rules_detail.py program_csv.csv --check CA1234567890
"""

import csv
import sys
import argparse
from collections import defaultdict

def parse_program_csv(filepath):
    """Parse program CSV and group by rule"""
    rules = defaultdict(set)
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            next(reader, None)  # Skip header
            
            for row in reader:
                if len(row) >= 2:
                    rule = row[0].strip()
                    value = row[1].strip()
                    if rule and value:
                        rules[rule].add(value)
    except Exception as e:
        print(f"Error reading file: {e}")
        return None
    return rules

def get_rule_numbers():
    """Return mapping of rule numbers to program rule names"""
    return {
        1: ['Rule1: Vkont', 'Rule1: Partner'],
        2: ['Rule2: Vkont', 'Rule2: Partner'],
        3: ['Rule3: Vkont', 'Rule3: Partner'],
        4: ['Rule4: Vkont', 'Rule4: Partner'],
        9: ['Rule9: Vkont', 'Rule9: Partner'],
        11: ['Rule11: Vkont', 'Rule11: Partner'],
        13: ['Rule13: Partner'],
        14: ['Rule14: Partner'],
        15: ['Rule15: Vkont', 'Rule15: Partner'],
        16: ['Rule16: Partner', 'Rule16: Vkont'],
        17: ['Rule17: Partner'],
    }

def print_rule_detail(rules, rule_num, show_missing=True, show_all=False):
    """Print detailed comparison for a specific rule"""
    rule_map = get_rule_numbers()
    rule_names = rule_map.get(rule_num, [])
    
    print(f"\n{'=' * 70}")
    print(f"RULE {rule_num} - DETAILED COMPARISON")
    print(f"{'=' * 70}")
    
    for rule_name in rule_names:
        values = rules.get(rule_name, set())
        count = len(values)
        
        print(f"\n{rule_name}: {count} records")
        print("-" * 50)
        
        if show_all and values:
            print("All values:")
            for v in sorted(values):
                print(f"  {v}")
        elif values:
            # Show sample
            samples = sorted(values)[:10]
            print(f"Sample values (first 10 of {count}):")
            for v in samples:
                print(f"  {v}")
            if count > 10:
                print(f"  ... and {count - 10} more")

def search_value(rules, value):
    """Search where a specific CA/BP appears"""
    print(f"\n{'=' * 70}")
    print(f"SEARCHING FOR: {value}")
    print(f"{'=' * 70}")
    
    found = False
    for rule, values in sorted(rules.items()):
        if value in values:
            print(f"✅ Found in: {rule}")
            found = True
    
    if not found:
        print(f"❌ NOT FOUND in any rule!")

def list_all_missing_values(rules):
    """List all values that appear only once (might indicate issues)"""
    all_values = defaultdict(list)
    
    for rule, values in rules.items():
        for v in values:
            all_values[v].append(rule)
    
    print(f"\n{'=' * 70}")
    print("VALUES APPEARING IN MULTIPLE RULES")
    print(f"{'=' * 70}")
    
    multi = {v: r for v, r in all_values.items() if len(r) > 1}
    if multi:
        print(f"Found {len(multi)} values in multiple rules:")
        for v, rule_list in sorted(multi.items())[:20]:
            print(f"  {v}: {rule_list}")
    else:
        print("No values appear in multiple rules")

def main():
    parser = argparse.ArgumentParser(description='Compare ENLIGHT Account CSV - Rule Detail')
    parser.add_argument('file', help='Program CSV file path')
    parser.add_argument('--rule', type=int, help='Analyze specific rule number')
    parser.add_argument('--check', help='Check if specific CA/BP exists')
    parser.add_argument('--all', action='store_true', help='Show all values (not just sample)')
    parser.add_argument('--multi', action='store_true', help='Show values in multiple rules')
    
    args = parser.parse_args()
    
    if not args.file:
        print("Usage: python compare_rules_detail.py <csv_file>")
        sys.exit(1)
    
    print(f"Reading: {args.file}")
    rules = parse_program_csv(args.file)
    
    if not rules:
        print("Failed to parse file")
        sys.exit(1)
    
    print(f"\nLoaded {len(rules)} rule types")
    
    if args.check:
        search_value(rules, args.check)
    elif args.rule:
        print_rule_detail(rules, args.rule, show_all=args.all)
    else:
        # Show summary of all rules
        print(f"\n{'=' * 70}")
        print("ALL RULES SUMMARY")
        print(f"{'=' * 70}")
        print(f"{'Rule':<25} {'Count':>10}")
        print("-" * 35)
        
        for rule in sorted(rules.keys()):
            print(f"{rule:<25} {len(rules[rule]):>10}")
        
        print(f"\n{'=' * 70}")
        print("USAGE EXAMPLES")
        print(f"{'=' * 70}")
        print("  python compare_rules_detail.py file.csv --rule 1")
        print("  python compare_rules_detail.py file.csv --check 1234567890")
        print("  python compare_rules_detail.py file.csv --rule 1 --all")
        print("  python compare_rules_detail.py file.csv --multi")

if __name__ == "__main__":
    main()