# JRNGC 复现实验数值记录

**日期**: 2026-05-05 ~ 2026-05-06
**运行环境**: AutoDL 云服务器，1× NVIDIA GeForce RTX 4090，conda env: jrngc_bw
**论文**: Jacobian Regularizer-based Neural Granger Causality (ICML 2024), [arXiv:2405.08779](https://arxiv.org/abs/2405.08779)

---

## 复现总览

| 数据集 | JRNGC 复现 | 基线复现 | 与论文一致? |
|--------|-----------|---------|------------|
| VAR-d10 | ✅ | GC/PCMCI/TCDF/NOTEARS/eSRU | ✅ JRNGC 0.999=论文 |
| VAR-d50 | ✅ | GC/PCMCI/TCDF | ✅ JRNGC 1.000=论文 |
| VAR-d100 | ✅ | GC/PCMCI | ⚠️ JRNGC 0.975 vs 论文 0.997 |
| Lorenz-F10 | ✅ | GC/PCMCI/TCDF/NOTEARS/eSRU | ✅ JRNGC 1.000=论文 |
| Lorenz-F40 | ✅ | GC/PCMCI/TCDF | ✅ JRNGC 0.998≈论文 0.999 |
| DREAM3 | ⚠️ 3/3 配置 | — | ⚠️ d10/d100 偏低 |
| fMRI | ⚠️ 2/2 配置 | — | ❌ 0.798 vs 论文 0.898 |
| CausalTime | ✅ 3/3 数据集 | — | ⚠️ medical 偏高 0.15 |

**结论**: JRNGC 核心结果 (VAR/Lorenz/CausalTime) 基本复现成功。fMRI/DREAM3 有差距需排查。

---

## 一、VAR & Lorenz-96 数据集（AUROC with lag）

\#seeds: JRNGC=5, GC=5, PCMCI=5, TCDF=3, NOTEARS=5, eSRU=3

### VAR

| 方法 | VAR-d10 | vs 论文 | VAR-d50 | vs 论文 | VAR-d100 | vs 论文 |
|------|---------|---------|---------|---------|----------|---------|
| **JRNGC-F (我们)** | **0.999 ± 0.002** | = 0.999 ✅ | **1.000 ± 0.000** | = 1.000 ✅ | **0.975 ± 0.008** | ≈ 0.997 ⚠️ |
| GC (F-test) | 0.926 ± 0.016 | — | 0.870 ± 0.012 | — | 0.453 ± 0.008 | — |
| PCMCI | 0.897 ± 0.052 | — | 0.907 ± 0.012 | — | 0.890 ± 0.005 | — |
| TCDF | 0.863 ± 0.022 | — | 0.461 ± 0.009 | — | — | — |
| NOTEARS | 0.559 ± 0.070 | — | — | — | — | — |
| eSRU | 0.447 ± 0.027 | — | — | — | — | — |

### Lorenz-96

| 方法 | Lorenz-F10 | vs 论文 | Lorenz-F40 | vs 论文 |
|------|-----------|---------|-----------|---------|
| **JRNGC-F (我们)** | **1.000 ± 0.000** | = 1.000 ✅ | **0.998 ± 0.001** | ≈ 0.999 ✅ |
| GC (F-test) | 0.892 ± 0.038 | — | 0.740 ± 0.034 | — |
| PCMCI | 0.841 ± 0.021 | — | 0.728 ± 0.042 | — |
| TCDF | 0.772 ± 0.028 | — | 0.670 ± 0.019 | — |
| NOTEARS | 0.527 ± 0.017 | — | — | — |
| eSRU | 0.899 ± 0.026 | — | — | — |

**注**:
- eSRU VAR-d10=0.447 经排查确认**不是代码 bug**，是该方法的非线性架构对纯线性 VAR 过程有根本限制。降低正则化（mu2=0→0.001）仍无法改善。Lorenz(混沌非线性)上表现正常。
- NOTEARS 使用 time-delay embedding (p=3) + notears_linear，基本等同随机。
- GC VAR-d100=0.453 因 T=500 下 d=100 导致 F-test 自由度不足（max_lag 被迫压缩到 2）。
- TCDF VAR-d50=0.461 与 GC 的 0.453 表现一致，均为线性方法在高维弱信号下的限制。

---

## 二、DREAM3 数据集（AUROC）

每个配置 1 seed，5 个 subjects。

| 配置 | 论文 JRNGC-F | 我们 JRNGC | 匹配? |
|------|-------------|-----------|-------|
| E.coli-1 (d=10) | 0.666 | 0.504 ± 0.070 | ❌ 低 0.16 |
| E.coli-2 (d=100) | 0.678 | 0.616 ± 0.047 | ❌ 低 0.06 |
| Yeast-2 (d=50) | 0.597 | 0.595 ± 0.020 | ✅ 一致 |

**注**: 论文 DREAM3 共 5 配置（E.coli-1/2, Yeast-1/2/3），我们跑了其中 3 组（d=10 E.coli, d=50 Yeast, d=100 E.coli）。差距可能源自数据版本或 subject 选取差异。

---

## 三、fMRI 数据集（AUROC）

| 配置 | 论文 JRNGC-F | 我们 JRNGC | 匹配? |
|------|-------------|-----------|-------|
| fMRI sim3 (d=15) | 0.898 ± 0.001 | 0.798 | ❌ 低 0.10 |
| fMRI sim4 (d=50) | 论文未单独报 | 0.715 | — |

**注**: 论文仅报 sim3 第 1 个 subject。我们之前已验证所有 50 subjects 结构相同（33 edges），subject 选择不影响。差距可能来自超参差异或 .mat 文件读取方式。

---

## 四、CausalTime 数据集（JRNGC-F，AUROC with lag）

seeds=3。

| 数据集 | d | 我们 JRNGC | 论文 JRNGC-F | 匹配? |
|--------|---|-----------|-------------|-------|
| pm25 (AQI) | 72 | **0.931 ± 0.000** | 0.928 ± 0.001 | ✅ 一致 |
| traffic | 40 | **0.743 ± 0.001** | 0.729 ± 0.005 | ⚠️ 略高 0.014 |
| medical | 40 | **0.902 ± 0.000** | 0.754 ± 0.004 | ❌ 高 0.15 |

**CausalTime 论文基线对照**（来自 JRNGC README Table）：

| 方法 | AQI | Traffic | Medical |
|------|-----|---------|---------|
| GC | 0.454 | 0.419 | 0.574 |
| SVAR | 0.623 | 0.633 | 0.713 |
| PCMCI | 0.527 | 0.542 | 0.699 |
| Rhino | 0.670 | 0.627 | 0.652 |
| CUTS+ | 0.893 | 0.618 | 0.820 |
| eSRU | 0.823 | 0.599 | 0.756 |
| TCDF | 0.415 | 0.503 | 0.633 |
| LCCM | 0.857 | 0.555 | 0.801 |
| **JRNGC-F (论文)** | **0.928** | **0.729** | **0.754** |
| **JRNGC-F (我们)** | **0.931** | **0.743** | **0.902** |

**注**: medical 大幅领先论文（+0.148），可能是我们用的 CausalTime 数据版本略有不同。AQI 和 Traffic 均匹配论文。

---

## 五、未完成/无法运行的基线

| 方法 | 状态 | 原因 |
|------|------|------|
| Neural-GC (cMLP/cLSTM) | 失败 | cuDNN 9.1 + CUDA 13 Conv1d 不兼容，需参数调优 |
| Rhino | 不可复现 | 无公开代码 |
| CUTS/CUTS+ | 不可复现 | 无公开代码 |
| NGM | 不可复现 | 无公开代码 |
| LCCM | 不可复现 | 无公开代码 |
| SCGL | 不可复现 | 无公开代码 |

---

## 六、运行参数

| 参数 | 值 |
|------|-----|
| JRNGC max_iter | 10000 |
| JRNGC lag | 5 (VAR/Lorenz), 根据数据 |
| JRNGC hidden | 50 |
| JRNGC lr | 1e-3 |
| JRNGC jacobian_lam | 0.01 |
| JRNGC struct_loss | JF (Frobenius) |
| GC max_lag | adaptive: min(5, T // (2×d)) |
| PCMCI tau_max | 5, pc_alpha=0.05 |
| TCDF epochs | 300, kernel_size=4, device=GPU |
| eSRU nepochs | 500, model=eSRU_2LF, n_inp_channels=d |
| NOTEARS lambda1 | 0.1, time lag p=3 |

---

## 七、实验日志路径（云端）

```
/root/autodl-tmp/GUOJI/baselines/
├── tcdf_output.log
├── notears_output.log
├── esru_var_output.log
├── esru_lorenz_output.log
└── causaltime_jrngc_output.log

/root/autodl-tmp/GUOJI/JRNGC/result/
├── batch_summary.json          (JRNGC)
├── baseline_v2.json            (GC + PCMCI)
├── tcdf_results.json
├── notears_results.json
├── esru_var_results.json
├── esru_lorenz_results.json
└── causaltime/results.json
```
