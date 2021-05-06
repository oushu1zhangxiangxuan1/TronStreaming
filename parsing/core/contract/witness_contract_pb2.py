# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: core/contract/witness_contract.proto

import sys
_b=sys.version_info[0]<3 and (lambda x:x) or (lambda x:x.encode('latin1'))
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor.FileDescriptor(
  name='core/contract/witness_contract.proto',
  package='protocol',
  syntax='proto3',
  serialized_options=_b('\n\030org.tron.protos.contractZ)github.com/tronprotocol/grpc-gateway/core'),
  serialized_pb=_b('\n$core/contract/witness_contract.proto\x12\x08protocol\";\n\x15WitnessCreateContract\x12\x15\n\rowner_address\x18\x01 \x01(\x0c\x12\x0b\n\x03url\x18\x02 \x01(\x0c\"B\n\x15WitnessUpdateContract\x12\x15\n\rowner_address\x18\x01 \x01(\x0c\x12\x12\n\nupdate_url\x18\x0c \x01(\x0c\"\xa2\x01\n\x13VoteWitnessContract\x12\x15\n\rowner_address\x18\x01 \x01(\x0c\x12\x31\n\x05votes\x18\x02 \x03(\x0b\x32\".protocol.VoteWitnessContract.Vote\x12\x0f\n\x07support\x18\x03 \x01(\x08\x1a\x30\n\x04Vote\x12\x14\n\x0cvote_address\x18\x01 \x01(\x0c\x12\x12\n\nvote_count\x18\x02 \x01(\x03\x42\x45\n\x18org.tron.protos.contractZ)github.com/tronprotocol/grpc-gateway/coreb\x06proto3')
)




_WITNESSCREATECONTRACT = _descriptor.Descriptor(
  name='WitnessCreateContract',
  full_name='protocol.WitnessCreateContract',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='owner_address', full_name='protocol.WitnessCreateContract.owner_address', index=0,
      number=1, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='url', full_name='protocol.WitnessCreateContract.url', index=1,
      number=2, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=50,
  serialized_end=109,
)


_WITNESSUPDATECONTRACT = _descriptor.Descriptor(
  name='WitnessUpdateContract',
  full_name='protocol.WitnessUpdateContract',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='owner_address', full_name='protocol.WitnessUpdateContract.owner_address', index=0,
      number=1, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='update_url', full_name='protocol.WitnessUpdateContract.update_url', index=1,
      number=12, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=111,
  serialized_end=177,
)


_VOTEWITNESSCONTRACT_VOTE = _descriptor.Descriptor(
  name='Vote',
  full_name='protocol.VoteWitnessContract.Vote',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='vote_address', full_name='protocol.VoteWitnessContract.Vote.vote_address', index=0,
      number=1, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='vote_count', full_name='protocol.VoteWitnessContract.Vote.vote_count', index=1,
      number=2, type=3, cpp_type=2, label=1,
      has_default_value=False, default_value=0,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
  ],
  extensions=[
  ],
  nested_types=[],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=294,
  serialized_end=342,
)

_VOTEWITNESSCONTRACT = _descriptor.Descriptor(
  name='VoteWitnessContract',
  full_name='protocol.VoteWitnessContract',
  filename=None,
  file=DESCRIPTOR,
  containing_type=None,
  fields=[
    _descriptor.FieldDescriptor(
      name='owner_address', full_name='protocol.VoteWitnessContract.owner_address', index=0,
      number=1, type=12, cpp_type=9, label=1,
      has_default_value=False, default_value=_b(""),
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='votes', full_name='protocol.VoteWitnessContract.votes', index=1,
      number=2, type=11, cpp_type=10, label=3,
      has_default_value=False, default_value=[],
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
    _descriptor.FieldDescriptor(
      name='support', full_name='protocol.VoteWitnessContract.support', index=2,
      number=3, type=8, cpp_type=7, label=1,
      has_default_value=False, default_value=False,
      message_type=None, enum_type=None, containing_type=None,
      is_extension=False, extension_scope=None,
      serialized_options=None, file=DESCRIPTOR),
  ],
  extensions=[
  ],
  nested_types=[_VOTEWITNESSCONTRACT_VOTE, ],
  enum_types=[
  ],
  serialized_options=None,
  is_extendable=False,
  syntax='proto3',
  extension_ranges=[],
  oneofs=[
  ],
  serialized_start=180,
  serialized_end=342,
)

_VOTEWITNESSCONTRACT_VOTE.containing_type = _VOTEWITNESSCONTRACT
_VOTEWITNESSCONTRACT.fields_by_name['votes'].message_type = _VOTEWITNESSCONTRACT_VOTE
DESCRIPTOR.message_types_by_name['WitnessCreateContract'] = _WITNESSCREATECONTRACT
DESCRIPTOR.message_types_by_name['WitnessUpdateContract'] = _WITNESSUPDATECONTRACT
DESCRIPTOR.message_types_by_name['VoteWitnessContract'] = _VOTEWITNESSCONTRACT
_sym_db.RegisterFileDescriptor(DESCRIPTOR)

WitnessCreateContract = _reflection.GeneratedProtocolMessageType('WitnessCreateContract', (_message.Message,), dict(
  DESCRIPTOR = _WITNESSCREATECONTRACT,
  __module__ = 'core.contract.witness_contract_pb2'
  # @@protoc_insertion_point(class_scope:protocol.WitnessCreateContract)
  ))
_sym_db.RegisterMessage(WitnessCreateContract)

WitnessUpdateContract = _reflection.GeneratedProtocolMessageType('WitnessUpdateContract', (_message.Message,), dict(
  DESCRIPTOR = _WITNESSUPDATECONTRACT,
  __module__ = 'core.contract.witness_contract_pb2'
  # @@protoc_insertion_point(class_scope:protocol.WitnessUpdateContract)
  ))
_sym_db.RegisterMessage(WitnessUpdateContract)

VoteWitnessContract = _reflection.GeneratedProtocolMessageType('VoteWitnessContract', (_message.Message,), dict(

  Vote = _reflection.GeneratedProtocolMessageType('Vote', (_message.Message,), dict(
    DESCRIPTOR = _VOTEWITNESSCONTRACT_VOTE,
    __module__ = 'core.contract.witness_contract_pb2'
    # @@protoc_insertion_point(class_scope:protocol.VoteWitnessContract.Vote)
    ))
  ,
  DESCRIPTOR = _VOTEWITNESSCONTRACT,
  __module__ = 'core.contract.witness_contract_pb2'
  # @@protoc_insertion_point(class_scope:protocol.VoteWitnessContract)
  ))
_sym_db.RegisterMessage(VoteWitnessContract)
_sym_db.RegisterMessage(VoteWitnessContract.Vote)


DESCRIPTOR._options = None
# @@protoc_insertion_point(module_scope)
