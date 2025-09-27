mod View {
    pub def escapeHtml(s: String): String = 
        s |> String.replace(src="&", dst="&amp;")
          |> String.replace(src="<", dst="&lt;")
          |> String.replace(src=">", dst="&gt;")
          |> String.replace(src="\"", dst="&quot;")
          |> String.replace(src="'", dst="&#39;")
}