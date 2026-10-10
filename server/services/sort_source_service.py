from sentence_transformers import SentenceTransformer
import numpy as np


class SortSourceService:
    def __init__(self):
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')

    def sort_sources(self, query: str, search_results: list[dict]):
        relevance_docs = []
        query_embedding = self.embedding_model.encode(query)
        for result in search_results:
            if not result.get('content'):
                continue
            result_embedding = self.embedding_model.encode(result['content'])
            similarity = float(
                np.dot(query_embedding, result_embedding)
                / (np.linalg.norm(query_embedding) * np.linalg.norm(result_embedding))
            )
            result['relevance'] = similarity
            if similarity > 0.3:
                relevance_docs.append(result)
        return sorted(relevance_docs, key=lambda x: x['relevance'], reverse=True)