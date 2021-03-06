// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Package partition metadata.
//
// DO NOT EDIT THIS FILE DIRECTLY.
// It has been generated with hw/ip/otp_ctrl/util/translate-mmap.py
<%
  def PascalCase(inp):
    oup = ''
    upper = True
    for k in inp.lower():
      if k == '_':
        upper = True
      else:
        oup += k.upper() if upper else k
        upper = False
    return oup
%>
package otp_ctrl_part_pkg;

  import otp_ctrl_reg_pkg::*;
  import otp_ctrl_pkg::*;

  localparam part_info_t PartInfo [NumPart] = '{
% for part in config["partitions"]:
    // ${part["name"]}
    '{
      variant:    ${part["variant"]},
      offset:     ${config["otp"]["byte_addr_width"]}'d${part["offset"]},
      size:       ${part["size"]},
      key_sel:    ${part["key_sel"] if part["key_sel"] != "NoKey" else "key_sel_e'('0)"},
      secret:     1'b${"1" if part["secret"] else "0"},
      hw_digest:  1'b${"1" if part["hw_digest"] else "0"},
      write_lock: 1'b${"1" if part["write_lock"].lower() == "digest" else "0"},
      read_lock:  1'b${"1" if part["read_lock"].lower() == "digest" else "0"}
    }${"" if loop.last else ","}
% endfor
  };

  typedef enum {
% for part in config["partitions"]:
    ${PascalCase(part["name"])}Idx,
% endfor
    // These are not "real partitions", but in terms of implementation it is convenient to
    // add these at the end of certain arrays.
    DaiIdx,
    LciIdx,
    KdiIdx,
    // Number of agents is the last idx+1.
    NumAgentsIdx
  } part_idx_e;

  parameter int NumAgents = int'(NumAgentsIdx);

  // Breakout types for easier access of individual items.
% for part in config["partitions"]:
  % if part["bkout_type"]:
  typedef struct packed {
    % for item in part["items"][::-1]:
      logic [${int(item["size"])*8-1}:0] ${item["name"].lower()};
    % endfor
  } otp_${part["name"].lower()}_data_t;
  typedef struct packed {
    // This reuses the same encoding as the life cycle signals for indicating valid status.
    lc_ctrl_pkg::lc_tx_t valid;
    otp_${part["name"].lower()}_data_t data;
  } otp_${part["name"].lower()}_t;
  % endif
% endfor

  // OTP invalid partition default for buffered partitions.
  parameter logic [${int(config["otp"]["depth"])*int(config["otp"]["width"])*8-1}:0] PartInvDefault = ${int(config["otp"]["depth"])*int(config["otp"]["width"])*8}'({
  % for k, part in enumerate(config["partitions"][::-1]):
    ${int(part["size"])*8}'({
    % for item in part["items"][::-1]:
      ${item["inv_default"]}${("\n    })," if k < len(config["partitions"])-1 else "\n    })});") if loop.last else ","}
    % endfor
  % endfor


endpackage : otp_ctrl_part_pkg
