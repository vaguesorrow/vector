import "quill"
export { marked } from "marked"

const Quill = globalThis.Quill
const Font = Quill.import("attributors/class/font")
Font.whitelist = ["fyl"]
Quill.register(Font, true)
const Size = Quill.import("attributors/style/size")
Size.whitelist = ["14px", "18px", "22px", "28px", "36px"]
Quill.register(Size, true)

export default Quill
