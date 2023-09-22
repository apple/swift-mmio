@attached(member)
public macro RegisterBank() =
  #externalMacro(
    module: "MMIOMacros",
    type: "RegisterBankMacro")

@attached(accessor)
public macro RegisterBank(_ offset: Int) =
  #externalMacro(
    module: "MMIOMacros",
    type: "RegisterBankOffsetMacro")
