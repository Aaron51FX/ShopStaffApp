# POS Error Code Notes

This file summarizes the POS-related codes that are actually visible in the current codebase.

## 1. Raw device/result codes confirmed in code

These come from the socket payload parsed in:
- `lib/data/services/legacy_pos_socket_manager.dart`
- historical reference: `lib/domain/services/pos_pay_old.dart`

Field positions used by the parser:
- `transactionType`: payload substring `[3, 6)`
- `resultString`: payload substring `[10, 13)`
- `resultMPFSString`: payload substring `[13, 16)`

Confirmed codes:

| Code | Source field | Current handling | Confidence | Notes |
| --- | --- | --- | --- | --- |
| `000` | `resultString` and often `resultMPFSString` | success | high | Current success condition is usually `resultString == "000"` and `resultMPFSString == "000"`. |
| `L06` | `resultString` | treated as cancel/interruption | high | In the old inline comment: password required, user returns without entering password. Seen in `transactionType == "900"` branch. |
| `L11` | `resultString` | treated as hard error | high | Routed to `onError(resultString)` after delay in non-`900/600/601` branch. |
| `T10` | `resultString` | treated as hard error | high | Old inline comment says transit-card timeout after ~30-40s. Routed to `onError(resultString)`. |
| any other non-empty code | `resultString` | treated as cancel/interactive stop | medium | For most unmatched non-empty codes, current code calls `onCancel(resultString, resultMPFSString)`. |

## 2. Transaction types seen in parser

These are not error codes, but they matter because the same `resultString` is interpreted differently by branch.

| Value | Meaning in current implementation |
| --- | --- |
| `900` | cancel-related transaction branch |
| `600` | success/report branch |
| `601` | success/report branch |
| other | generic payment branch |

## 3. MPFS field

`resultMPFSString` is currently only collected and surfaced with cancel status:
- `lib/data/services/pos_payment_service_impl.dart`
- `lib/presentations/payment/widgets/status_hero.dart`

Current status:
- no code table exists in repo for MPFS values
- UI currently displays it as raw `mpfs`
- this needs device/vendor documentation or production samples

## 4. Backend / gateway-side non-device failures

These are not POS terminal `errorCode`s. They are backend or local integration failures.

Observed sources:
- `CardPaymentRequestData.exceptionMessage`
- remote `msg` / `message`
- thrown internal identifiers such as `POS_REQUEST_DATA_MISSING`

Examples:
- `POS_REQUEST_DATA_MISSING`
- `POS_CONFIG_MISSING`
- `POS_CANCEL_FAILED`
- `POS_SESSION_MISSING`

These should stay in a separate mapping table from device error codes.

## 5. App-internal errorCode currently used in payment result

| Code | Layer | Meaning |
| --- | --- | --- |
| `CANCEL_FORCE_EXIT` | `payment_flow_viewmodel.dart` | operator forced exit after cancel failure; not from POS device |

## 6. What is missing today

The repo does not contain:
- an official POS vendor error code table
- MPFS code documentation
- a backend enum/spec for `exceptionMessage`

So the currently safe list of confirmed device-side codes is:
- `000`
- `L06`
- `L11`
- `T10`

Everything else should currently be considered "observed raw code, meaning unknown until sampled or documented".

## 7. Recommended next step

To complete the mapping table, capture and store:
- raw `resultString`
- raw `resultMPFSString`
- `transactionType`
- payment channel / payType
- whether flow ended in success / cancel / failure

Once that data exists, the mapping can be split into:
- device error codes
- MPFS supplementary codes
- backend integration errors
