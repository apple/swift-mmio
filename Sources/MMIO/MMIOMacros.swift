@attached(member, names: named(unsafeAddress), named(init))
public macro RegisterBank() =
  #externalMacro(
    module: "MMIOMacros",
    type: "RegisterBankMacro")

@attached(accessor)
public macro RegisterBank(offset: Int) =
  #externalMacro(
    module: "MMIOMacros",
    type: "RegisterBankOffsetMacro")
