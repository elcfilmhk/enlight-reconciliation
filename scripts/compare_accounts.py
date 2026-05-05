#!/usr/bin/env python3
"""
Compare ENLIGHT Migration Program CSV vs Validation Rules
Format: RULE,VKONT/PARTNER (e.g., "Rule1: Vkont","1234567890")

Usage:
    python compare_accounts.py program_output.csv
    python compare_accounts.py program_output.csv --rule 1
"""

import csv
import sys
import argparse
from collections import defaultdict

def parse_program_csv(filepath):
    """Parse program CSV and group by rule"""
    rules = defaultdict(set)
    vkont_by_rule = defaultdict(set)
    partner_by_rule = defaultdict(set)
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            header = next(reader, None)  # Skip header row
            
            for row in reader:
                if len(row) >= 2:
                    rule = row[0].strip()
                    value = row[1].strip()
                    if value:
                        rules[rule].add(value)
                        
                        # Categorize as VKONT or Partner
                        if 'Vkont' in rule or 'vkont' in rule:
                            vkont_by_rule[rule].add(value)
                        elif 'Partner' in rule or 'partner' in rule:
                            partner_by_rule[rule].add(value)
                        else:
                            # Try to determine from pattern
                            # VKONT usually 10+ digits, Partner may vary
                            if value.isdigit() and len(value) >= 10:
                                vkont_by_rule[rule].add(value)
                            else:
                                partner_by_rule[rule].add(value)
    except Exception as e:
        print(f"Error reading file: {e}")
        return None
    
    return {
        'rules': rules,
        'vkont': vkont_by_rule,
        'partner': partner_by_rule
    }

def print_summary(data):
    print("\n" + "=" * 70)
    print("PROGRAM CSV SUMMARY - BY RULE")
    print("=" * 70)
    
    for rule in sorted(data['rules'].keys()):
        values = data['rules'][rule]
        print(f"{rule:20} : {len(values):>10} records")
    
    print("\n" + "-" * 70)
    print("VKONT COUNT BY RULE:")
    print("-" * 70)
    for rule in sorted(data['vkont'].keys()):
        print(f"{rule:20} : {len(data['vkont'][rule]):>10} VKONT")
    
    print("\n" + "-" * 70)
    print("PARTNER COUNT BY RULE:")
    print("-" * 70)
    for rule in sorted(data['partner'].keys()):
        print(f"{rule:20} : {len(data['partner'][rule]):>10} BP")

def analyze_rule(data, rule_num):
    """Analyze specific rule"""
    print(f"\n{'=' * 70}")
    print(f"DETAILED ANALYSIS - RULE {rule_num}")
    print(f"{'=' * 70}")
    
    # Find matching rules
    matching = [r for r in data['rules'].keys() if f'Rule{rule_num}' in r]
    
    for rule in matching:
        print(f"\n{rule}:")
        print(f"  Total records: {len(data['rules'][rule])}")
        
        vkont = data['vkont'].get(rule, set())
        partner = data['partner'].get(rule, set())
        
        if vkont:
            print(f"  VKONT: {len(vkont)}")
            samples = list(vkont)[:3]
            print(f"    Sample: {samples}")
        if partner:
            print(f"  Partner: {len(partner)}")
            samples = list(partner)[:3]
            print(f"    Sample: {samples}")

def main():
    parser = argparse.ArgumentParser(description='Compare ENLIGHT Account CSV')
    parser.add_argument('file', help='Program CSV file path')
    parser.add_argument('--rule', type=int, help='Analyze specific rule number')
    parser.add_argument('--check-vkont', help='Check if VKONT exists in any rule')
    
    args = parser.parse_args()
    
    print(f"Reading: {args.file}")
    data = parse_program_csv(args.file)
    
    if not data:
        print("Failed to parse file")
        sys.exit(1)
    
    if args.check_vkont:
        vkont_to_find = args.check_vkont
        print(f"\n{'=' * 70}")
        print(f"CHECKING VKONT: {vkont_to_find}")
        print(f"{'=' * 70}")
        
        found = False
        for rule, values in data['rules'].items():
            if vkont_to_find in values:
                print(f"  Found in: {rule}")
                found = True
        
        if not found:
            print("  NOT FOUND in any rule!")
        return
    
    if args.rule:
        analyze_rule(data, args.rule)
    else:
        print_summary(data)
    
    print("\n" + "=" * 70)
    print("Usage for detailed analysis:")
    print("  python compare_accounts.py file.csv --rule 1")
    print("  python compare_accounts.py file.csv --check-vkont 1234567890")
    print("=" * 70)

if __name__ == "__main__":
    main()