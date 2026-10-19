import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final plugin = _Plugin();

class _Plugin extends Plugin {
  @override
  String get name => 'plugin';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(_Rule());
  }
}

class _Rule extends AnalysisRule {
  _Rule() : super(name: 'once_per_file', description: '');

  @override
  LintCode get diagnosticCode =>
      const LintCode('once_per_file', 'Reported once per file.');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}
